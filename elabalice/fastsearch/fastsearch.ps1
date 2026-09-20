<#
.SYNOPSIS
    fastsearch.ps1 - PowerShell port of the boolean-logic CLI search (no prebuilt exe).

.DESCRIPTION
    Drop-in PowerShell replacement for fastsearch.exe. The original 6 C# source
    files (Program / BooleanExpressionMatcher / FilePatternMatcher / FileScanner /
    TextFileReader / EncodeSpellCard) are embedded verbatim and compiled in-process
    via Add-Type on first run, then [fastsearch.Program]::Main is invoked.

    Because the C# is byte-for-byte the same logic as the exe, EVERY semantic
    detail is inherited unchanged - including the verified gotchas (per-line AND,
    "missing operator between two terms" on spaces, escape-merging of \&\&,
    substring + case-insensitive by default, output format, exit codes).

    No compiler toolchain, no exe to ship. Pure text -> easy to maintain.
    Extension hooks live in the EXTENSION POINT block below.

.NOTES
    C# source of truth: 0_FastTool/4_FastSearch/workspace/FastSearch/fastsearch/*.cs
    Usage / semantics:   see SKILL.md next to this file.
#>

# 1) Register GB18030 on .NET Core / PowerShell 7. On .NET Framework (PS 5.1)
#    the provider type does not exist and GB18030 is already available -> ignore.
try {
    [System.Text.Encoding]::RegisterProvider([System.Text.CodePages.CodePagesEncodingProvider]::Instance)
} catch {}

# 2) Compile embedded C# once per process (the type check guards dot-sourcing).
if (-not ('fastsearch.Program' -as [type])) {
    $csharp = @'
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;
using EncodeSpellCard;

namespace fastsearch
{
    public static class Program
    {
        private const int ExitMatched = 0;
        private const int ExitNoMatch = 1;
        private const int ExitInvalidArguments = 2;

        public static int Main(string[] args)
        {
            CliOptions options;
            string parseError;
            if (!CliOptions.TryParse(args, out options, out parseError))
            {
                if (!string.IsNullOrEmpty(parseError))
                {
                    Console.Error.WriteLine("Error: {0}", parseError);
                }
                PrintUsage();
                return ExitInvalidArguments;
            }

            if (options.ShowHelp)
                return ExitMatched;

            if (!Directory.Exists(options.SearchRoot))
            {
                Console.Error.WriteLine("Error: search root does not exist: {0}", options.SearchRoot);
                return ExitInvalidArguments;
            }

            try
            {
                var patternMatcher = new FilePatternMatcher(options.FilePattern);

                // Only build the expression matcher when not in list-files-only mode
                BooleanExpressionMatcher expressionMatcher = null;
                if (!options.ListFilesOnly)
                {
                    expressionMatcher = BooleanExpressionMatcher.Create(options.Expression, options.CaseSensitive);
                }

                long scannedFiles = 0;
                long matchedFiles = 0;
                long matchedLines = 0;
                long unreadableFiles = 0;

                foreach (string filePath in FileScanner.EnumerateFilesSafe(options.SearchRoot, patternMatcher, options.ExcludedDirectoryNames))
                {
                    scannedFiles++;

                    // Mode A: only scan file names (fastsearch.exe "*.log")
                    if (options.ListFilesOnly)
                    {
                        Console.WriteLine(filePath);
                        matchedFiles++;
                        continue;
                    }

                    // Mode B: full-text search + scope context
                    string[] lines;
                    string readError;
                    if (!TextFileReader.TryReadAllLines(filePath, out lines, out readError))
                    {
                        unreadableFiles++;
                        continue;
                    }

                    bool hasMatchInCurrentFile = false;
                    int lastPrintedLine = -1;

                    for (int i = 0; i < lines.Length; i++)
                    {
                        if (!expressionMatcher.IsMatch(lines[i]))
                        {
                            continue;
                        }

                        if (!hasMatchInCurrentFile)
                        {
                            hasMatchInCurrentFile = true;
                            matchedFiles++;
                        }

                        matchedLines++;

                        int start = Math.Max(0, i - options.Scope);
                        int end = Math.Min(lines.Length - 1, i + options.Scope);

                        if (lastPrintedLine != -1 && start > lastPrintedLine + 1)
                            Console.WriteLine("  ---");

                        for (int j = start; j <= end; j++)
                        {
                            if (j <= lastPrintedLine) continue;
                            string prefix = (j == i) ? ">>" : "  ";
                            Console.WriteLine("{0} {1}({2}): {3}", prefix, filePath, j + 1, lines[j]);
                            lastPrintedLine = j;
                        }
                    }
                }

                Console.Error.WriteLine("Scanned files: {0}", scannedFiles);
                Console.Error.WriteLine("Matched files: {0}", matchedFiles);
                if (!options.ListFilesOnly)
                {
                    Console.Error.WriteLine("Matched lines: {0}", matchedLines);
                }
                Console.Error.WriteLine("Unreadable files: {0}", unreadableFiles);

                if (matchedFiles == 0)
                {
                    Console.Error.WriteLine("No matches found.");
                    return ExitNoMatch;
                }

                return ExitMatched;
            }
            catch (FormatException ex)
            {
                Console.Error.WriteLine("Error: {0}", ex.Message);
                return ExitInvalidArguments;
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine("Fatal error: {0}", ex.Message);
                return ExitInvalidArguments;
            }
        }

        private static void PrintUsage()
        {
            Console.WriteLine("fastsearch - FastTool CLI logical search");
            Console.WriteLine("Usage:");
            Console.WriteLine("  fastsearch.exe \"<file-pattern>\"                  (Only list file names)");
            Console.WriteLine("  fastsearch.exe \"<file-pattern>\" \"<expression>\" [search-root] [options]");
            Console.WriteLine();
            Console.WriteLine("Options:");
            Console.WriteLine("  -s, --scope <N>      Show N lines around matches (Default: 0)");
            Console.WriteLine("  --root, -r           explicit search root");
            Console.WriteLine("  --exclude-dir, -x    skip directories by name; repeatable");
            Console.WriteLine("  --case-sensitive     case-sensitive term matching");
            Console.WriteLine();

            Console.WriteLine("Example:");
            Console.WriteLine(" fastsearch.exe \"*.log\" \"Keyword1&(Keyword2|Keyword3)\"");
            Console.WriteLine(" fastsearch.exe \"*.log\" \"Keyword1&(Keyword2|Keyword3)\" --root \"D:\\Test\"");
            Console.WriteLine(" fastsearch.exe \"*.cs\" \"TODO\" --root \"D:\\Work\" --exclude-dir packages");
            Console.WriteLine();
            Console.WriteLine("Expression operators:");
            Console.WriteLine(" &  logical AND");
            Console.WriteLine(" |  logical OR");
            Console.WriteLine(" !  logical NOT");
            Console.WriteLine(" () grouping");
            Console.WriteLine("Options:");
            Console.WriteLine(" --root, -r     explicit search root");
            Console.WriteLine(" --exclude-dir, -x skip directories by name; repeatable");
            Console.WriteLine(" --case-sensitive  case-sensitive term matching");
            Console.WriteLine("Default skipped dirs: bin, obj, .git, .vs");
            Console.WriteLine();
            Console.WriteLine("Stem/Affix guidance:");
            Console.WriteLine(" Prefer concept clusters over exact field names.");
            Console.WriteLine(" Split queries into stems/affixes like HDMI / Camera / Ingest / Room, then combine with & and |.");
            Console.WriteLine(" Avoid long glued tokens like HDMIIngestCamera; they are usually a poor query.");
            Console.WriteLine(" Example: ((HDMI&Camera)|(HDMI&Ingest)|(HDMI&Content))&(Rigel|Room|Teams)");
            Console.WriteLine(" Example: HDMI&Camera&(!USB) can precisely exclude USB Camera results.");
            Console.WriteLine(@"Escape special chars in term with \ , such as \&, \|, \!, \(, \)");
        }

        private sealed class CliOptions
        {
            private static readonly string[] DefaultExcludedDirectories = new[] { "bin", "obj", ".git", ".vs" };

            public string FilePattern;
            public string Expression;
            public string SearchRoot;
            public bool CaseSensitive;
            public bool ShowHelp;
            public bool ListFilesOnly;
            public int Scope = 0;
            public HashSet<string> ExcludedDirectoryNames;

            public static bool TryParse(string[] args, out CliOptions options, out string error)
            {
                options = new CliOptions();
                error = string.Empty;
                options.ExcludedDirectoryNames = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                AddDefaultExcludedDirectories(options.ExcludedDirectoryNames);

                if (args == null || args.Length == 0)
                {
                    error = "missing required arguments.";
                    return false;
                }

                if (args.Length == 1 && IsHelpFlag(args[0]))
                {
                    options.ShowHelp = true;
                    return true;
                }

                options.FilePattern = args[0];
                options.SearchRoot = Environment.CurrentDirectory;

                int nextIdx = 1;
                // Decide whether this is list-files-only mode
                if (args.Length > 1 && !args[1].StartsWith("-") && !IsHelpFlag(args[1]))
                {
                    options.Expression = args[1];
                    options.ListFilesOnly = false;
                    nextIdx = 2;
                }
                else
                {
                    options.ListFilesOnly = true;
                }

                bool rootSpecified = false;
                for (int i = nextIdx; i < args.Length; i++)
                {
                    string arg = args[i];
                    if (arg.Equals("--case-sensitive", StringComparison.OrdinalIgnoreCase))
                    {
                        options.CaseSensitive = true;
                        continue;
                    }
                    if (IsHelpFlag(arg))
                    {
                        options.ShowHelp = true;
                        continue;
                    }
                    if (arg.Equals("-s", StringComparison.OrdinalIgnoreCase) || arg.Equals("--scope", StringComparison.OrdinalIgnoreCase))
                    {
                        if (i + 1 >= args.Length || !int.TryParse(args[++i], out options.Scope))
                        {
                            error = "invalid scope value.";
                            return false;
                        }
                        continue;
                    }
                    if (IsRootFlag(arg))
                    {
                        if (rootSpecified) { error = "multiple search roots provided."; return false; }
                        if (i + 1 >= args.Length) { error = "missing value for --root."; return false; }
                        options.SearchRoot = Path.GetFullPath(args[++i]);
                        rootSpecified = true;
                        continue;
                    }
                    if (IsExcludeDirectoryFlag(arg))
                    {
                        if (i + 1 >= args.Length) { error = "missing value for --exclude-dir."; return false; }
                        if (!TryAddExcludedDirectory(options.ExcludedDirectoryNames, args[++i], out error)) return false;
                        continue;
                    }

                    // Tolerate assignment form --root=D:\ or -x=bin
                    string rootValue;
                    if (TryParseRootAssignment(arg, out rootValue))
                    {
                        options.SearchRoot = Path.GetFullPath(rootValue);
                        rootSpecified = true;
                        continue;
                    }

                    // Tolerate positional root (anything not starting with '-')
                    if (!arg.StartsWith("-") && !rootSpecified)
                    {
                        options.SearchRoot = Path.GetFullPath(arg);
                        rootSpecified = true;
                    }
                }

                if (string.IsNullOrWhiteSpace(options.FilePattern))
                {
                    error = "file pattern cannot be empty.";
                    return false;
                }
                if (!options.ListFilesOnly && string.IsNullOrWhiteSpace(options.Expression))
                {
                    error = "expression cannot be empty.";
                    return false;
                }

                return true;
            }

            // NOTE: Add-Type on Windows PowerShell 5.1 compiles via the legacy CodeDom
            // provider, which tops out at C# 5 - no expression-bodied members (=> ...).
            // Use classic method bodies so the embedded source compiles everywhere.
            private static bool IsHelpFlag(string arg)
            {
                return arg.Equals("-h", StringComparison.OrdinalIgnoreCase) || arg.Equals("--help", StringComparison.OrdinalIgnoreCase) || arg.Equals("/?", StringComparison.OrdinalIgnoreCase);
            }
            private static bool IsRootFlag(string arg)
            {
                return arg.Equals("--root", StringComparison.OrdinalIgnoreCase) || arg.Equals("-r", StringComparison.OrdinalIgnoreCase);
            }
            private static bool IsExcludeDirectoryFlag(string arg)
            {
                return arg.Equals("--exclude-dir", StringComparison.OrdinalIgnoreCase) || arg.Equals("-x", StringComparison.OrdinalIgnoreCase);
            }

            private static bool TryParseRootAssignment(string arg, out string rootValue)
            {
                rootValue = null;
                if (arg.StartsWith("--root=", StringComparison.OrdinalIgnoreCase)) { rootValue = arg.Substring(7); return true; }
                if (arg.StartsWith("-r=", StringComparison.OrdinalIgnoreCase)) { rootValue = arg.Substring(3); return true; }
                return false;
            }

            private static void AddDefaultExcludedDirectories(HashSet<string> excludedNames)
            {
                foreach (var d in DefaultExcludedDirectories) excludedNames.Add(d);
            }

            private static bool TryAddExcludedDirectory(HashSet<string> excludedNames, string name, out string error)
            {
                error = string.Empty;
                if (string.IsNullOrWhiteSpace(name)) { error = "excluded directory name empty."; return false; }
                string trimmed = name.Trim();
                if (trimmed.Contains(Path.DirectorySeparatorChar.ToString()) || trimmed.Contains(Path.AltDirectorySeparatorChar.ToString()))
                {
                    error = "exclude-dir must be a name, not a path.";
                    return false;
                }
                excludedNames.Add(trimmed);
                return true;
            }
        }
    }

    internal sealed class BooleanExpressionMatcher
    {
        private readonly List<ExpressionToken> _rpnTokens;
        private readonly StringComparison _comparison;

        private BooleanExpressionMatcher(List<ExpressionToken> rpnTokens, bool caseSensitive)
        {
            _rpnTokens = rpnTokens;
            _comparison = caseSensitive ? StringComparison.Ordinal : StringComparison.OrdinalIgnoreCase;
        }

        public static BooleanExpressionMatcher Create(string expression, bool caseSensitive)
        {
            if (string.IsNullOrWhiteSpace(expression))
            {
                throw new FormatException("expression cannot be empty.");
            }

            List<ExpressionToken> tokens = Tokenize(expression);
            List<ExpressionToken> rpn = ConvertToRpn(tokens);
            return new BooleanExpressionMatcher(rpn, caseSensitive);
        }

        public bool IsMatch(string line)
        {
            if (line == null)
            {
                line = string.Empty;
            }

            var valueStack = new Stack<bool>();

            for (int i = 0; i < _rpnTokens.Count; i++)
            {
                ExpressionToken token = _rpnTokens[i];
                switch (token.Type)
                {
                    case TokenType.Term:
                        valueStack.Push(line.IndexOf(token.Value, _comparison) >= 0);
                        break;

                    case TokenType.Not:
                        if (valueStack.Count < 1)
                        {
                            throw new FormatException("invalid expression: NOT has no operand.");
                        }

                        valueStack.Push(!valueStack.Pop());
                        break;

                    case TokenType.And:
                        if (valueStack.Count < 2)
                        {
                            throw new FormatException("invalid expression: AND has insufficient operands.");
                        }

                        bool andRight = valueStack.Pop();
                        bool andLeft = valueStack.Pop();
                        valueStack.Push(andLeft && andRight);
                        break;

                    case TokenType.Or:
                        if (valueStack.Count < 2)
                        {
                            throw new FormatException("invalid expression: OR has insufficient operands.");
                        }

                        bool orRight = valueStack.Pop();
                        bool orLeft = valueStack.Pop();
                        valueStack.Push(orLeft || orRight);
                        break;

                    default:
                        throw new FormatException("invalid token found during evaluation.");
                }
            }

            if (valueStack.Count != 1)
            {
                throw new FormatException("invalid expression: unable to resolve to one value.");
            }

            return valueStack.Pop();
        }

        private static List<ExpressionToken> Tokenize(string expression)
        {
            var tokens = new List<ExpressionToken>();
            int index = 0;

            while (index < expression.Length)
            {
                char ch = expression[index];

                if (char.IsWhiteSpace(ch))
                {
                    index++;
                    continue;
                }

                if (ch == '&')
                {
                    tokens.Add(new ExpressionToken(TokenType.And));
                    index++;
                    continue;
                }

                if (ch == '|')
                {
                    tokens.Add(new ExpressionToken(TokenType.Or));
                    index++;
                    continue;
                }

                if (ch == '!')
                {
                    tokens.Add(new ExpressionToken(TokenType.Not));
                    index++;
                    continue;
                }

                if (ch == '(')
                {
                    tokens.Add(new ExpressionToken(TokenType.LeftParen));
                    index++;
                    continue;
                }

                if (ch == ')')
                {
                    tokens.Add(new ExpressionToken(TokenType.RightParen));
                    index++;
                    continue;
                }

                var termBuilder = new StringBuilder();
                while (index < expression.Length)
                {
                    ch = expression[index];

                    if (ch == '\\')
                    {
                        if (index + 1 >= expression.Length)
                        {
                            throw new FormatException("escape character '\\' cannot be the final character.");
                        }

                        termBuilder.Append(expression[index + 1]);
                        index += 2;
                        continue;
                    }

                    if (IsOperatorCharacter(ch) || char.IsWhiteSpace(ch))
                    {
                        break;
                    }

                    termBuilder.Append(ch);
                    index++;
                }

                if (termBuilder.Length == 0)
                {
                    throw new FormatException(string.Format("invalid character near index {0}.", index));
                }

                tokens.Add(new ExpressionToken(TokenType.Term, termBuilder.ToString()));
            }

            return tokens;
        }

        private static List<ExpressionToken> ConvertToRpn(List<ExpressionToken> tokens)
        {
            var output = new List<ExpressionToken>();
            var operators = new Stack<ExpressionToken>();
            bool expectingOperand = true;

            for (int i = 0; i < tokens.Count; i++)
            {
                ExpressionToken token = tokens[i];

                switch (token.Type)
                {
                    case TokenType.Term:
                        if (!expectingOperand)
                        {
                            throw new FormatException("missing operator between two terms.");
                        }

                        output.Add(token);
                        expectingOperand = false;
                        break;

                    case TokenType.Not:
                        if (!expectingOperand)
                        {
                            throw new FormatException("'!' must appear before a term or sub-expression.");
                        }

                        operators.Push(token);
                        break;

                    case TokenType.And:
                    case TokenType.Or:
                        if (expectingOperand)
                        {
                            throw new FormatException(string.Format("operator '{0}' is missing left operand.", token.ToSymbol()));
                        }

                        while (operators.Count > 0 && operators.Peek().IsOperator)
                        {
                            ExpressionToken top = operators.Peek();
                            if ((token.IsLeftAssociative && token.Precedence <= top.Precedence) ||
                                (!token.IsLeftAssociative && token.Precedence < top.Precedence))
                            {
                                output.Add(operators.Pop());
                                continue;
                            }

                            break;
                        }

                        operators.Push(token);
                        expectingOperand = true;
                        break;

                    case TokenType.LeftParen:
                        if (!expectingOperand)
                        {
                            throw new FormatException("missing operator before '('.");
                        }

                        operators.Push(token);
                        break;

                    case TokenType.RightParen:
                        if (expectingOperand)
                        {
                            throw new FormatException("')' cannot follow an operator directly.");
                        }

                        bool foundLeftParen = false;
                        while (operators.Count > 0)
                        {
                            ExpressionToken top = operators.Pop();
                            if (top.Type == TokenType.LeftParen)
                            {
                                foundLeftParen = true;
                                break;
                            }

                            output.Add(top);
                        }

                        if (!foundLeftParen)
                        {
                            throw new FormatException("parentheses are not balanced.");
                        }

                        expectingOperand = false;
                        break;
                }
            }

            if (expectingOperand)
            {
                throw new FormatException("expression cannot end with an operator.");
            }

            while (operators.Count > 0)
            {
                ExpressionToken token = operators.Pop();
                if (token.Type == TokenType.LeftParen || token.Type == TokenType.RightParen)
                {
                    throw new FormatException("parentheses are not balanced.");
                }

                output.Add(token);
            }

            return output;
        }

        private static bool IsOperatorCharacter(char ch)
        {
            return ch == '&' || ch == '|' || ch == '!' || ch == '(' || ch == ')';
        }

        private enum TokenType
        {
            Term,
            And,
            Or,
            Not,
            LeftParen,
            RightParen
        }

        private sealed class ExpressionToken
        {
            public TokenType Type { get; private set; }
            public string Value { get; private set; }

            public int Precedence
            {
                get
                {
                    switch (Type)
                    {
                        case TokenType.Not:
                            return 3;
                        case TokenType.And:
                            return 2;
                        case TokenType.Or:
                            return 1;
                        default:
                            return 0;
                    }
                }
            }

            public bool IsLeftAssociative
            {
                get
                {
                    return Type != TokenType.Not;
                }
            }

            public bool IsOperator
            {
                get
                {
                    return Type == TokenType.And || Type == TokenType.Or || Type == TokenType.Not;
                }
            }

            public ExpressionToken(TokenType type)
                : this(type, string.Empty)
            {
            }

            public ExpressionToken(TokenType type, string value)
            {
                Type = type;
                Value = value ?? string.Empty;
            }

            public string ToSymbol()
            {
                switch (Type)
                {
                    case TokenType.And:
                        return "&";
                    case TokenType.Or:
                        return "|";
                    case TokenType.Not:
                        return "!";
                    case TokenType.LeftParen:
                        return "(";
                    case TokenType.RightParen:
                        return ")";
                    case TokenType.Term:
                        return Value;
                    default:
                        return string.Empty;
                }
            }
        }
    }

    internal sealed class FilePatternMatcher
    {
        private readonly List<Regex> _compiledPatterns = new List<Regex>();

        public FilePatternMatcher(string patternExpression)
        {
            if (string.IsNullOrWhiteSpace(patternExpression))
            {
                throw new FormatException("file pattern cannot be empty.");
            }

            string[] rawPatterns = patternExpression.Split(new[] { '|', ';', ',' }, StringSplitOptions.RemoveEmptyEntries);
            for (int i = 0; i < rawPatterns.Length; i++)
            {
                string pattern = rawPatterns[i].Trim();
                if (pattern.Length == 0)
                {
                    continue;
                }

                string regexPattern = "^" + WildcardToRegex(pattern) + "$";
                _compiledPatterns.Add(new Regex(regexPattern, RegexOptions.IgnoreCase | RegexOptions.CultureInvariant));
            }

            if (_compiledPatterns.Count == 0)
            {
                throw new FormatException("file pattern does not contain valid wildcard parts.");
            }
        }

        public bool IsMatch(string filePath)
        {
            string fileName = Path.GetFileName(filePath);
            for (int i = 0; i < _compiledPatterns.Count; i++)
            {
                if (_compiledPatterns[i].IsMatch(fileName))
                {
                    return true;
                }
            }

            return false;
        }

        private static string WildcardToRegex(string wildcardPattern)
        {
            var builder = new StringBuilder();
            for (int i = 0; i < wildcardPattern.Length; i++)
            {
                char ch = wildcardPattern[i];
                switch (ch)
                {
                    case '*':
                        builder.Append(".*");
                        break;
                    case '?':
                        builder.Append('.');
                        break;
                    default:
                        builder.Append(Regex.Escape(ch.ToString()));
                        break;
                }
            }

            return builder.ToString();
        }
    }

    internal static class FileScanner
    {
        public static IEnumerable<string> EnumerateFilesSafe(string rootDirectory, FilePatternMatcher patternMatcher, ISet<string> excludedDirectoryNames)
        {
            if (string.IsNullOrWhiteSpace(rootDirectory) || !Directory.Exists(rootDirectory) || patternMatcher == null)
            {
                yield break;
            }

            var pendingDirectories = new Stack<string>();
            pendingDirectories.Push(rootDirectory);

            while (pendingDirectories.Count > 0)
            {
                string currentDirectory = pendingDirectories.Pop();

                foreach (string filePath in EnumerateFilesInDirectorySafe(currentDirectory))
                {
                    if (patternMatcher.IsMatch(filePath))
                    {
                        yield return filePath;
                    }
                }

                foreach (string subDirectory in EnumerateDirectoriesSafe(currentDirectory))
                {
                    if (!ShouldSkipDirectory(subDirectory, excludedDirectoryNames))
                    {
                        pendingDirectories.Push(subDirectory);
                    }
                }
            }
        }

        private static bool ShouldSkipDirectory(string directoryPath, ISet<string> excludedDirectoryNames)
        {
            if (excludedDirectoryNames == null || excludedDirectoryNames.Count == 0)
            {
                return false;
            }

            string directoryName = Path.GetFileName(directoryPath);
            return !string.IsNullOrEmpty(directoryName) && excludedDirectoryNames.Contains(directoryName);
        }

        private static IEnumerable<string> EnumerateFilesInDirectorySafe(string directory)
        {
            IEnumerator<string> enumerator = null;
            try
            {
                enumerator = Directory.EnumerateFiles(directory, "*", SearchOption.TopDirectoryOnly).GetEnumerator();
            }
            catch (UnauthorizedAccessException)
            {
                yield break;
            }
            catch (PathTooLongException)
            {
                yield break;
            }
            catch (IOException)
            {
                yield break;
            }

            using (enumerator)
            {
                while (true)
                {
                    bool hasNext;
                    try
                    {
                        hasNext = enumerator.MoveNext();
                    }
                    catch (UnauthorizedAccessException)
                    {
                        yield break;
                    }
                    catch (PathTooLongException)
                    {
                        yield break;
                    }
                    catch (IOException)
                    {
                        yield break;
                    }

                    if (!hasNext)
                    {
                        yield break;
                    }

                    yield return enumerator.Current;
                }
            }
        }

        private static IEnumerable<string> EnumerateDirectoriesSafe(string directory)
        {
            IEnumerator<string> enumerator = null;
            try
            {
                enumerator = Directory.EnumerateDirectories(directory, "*", SearchOption.TopDirectoryOnly).GetEnumerator();
            }
            catch (UnauthorizedAccessException)
            {
                yield break;
            }
            catch (PathTooLongException)
            {
                yield break;
            }
            catch (IOException)
            {
                yield break;
            }

            using (enumerator)
            {
                while (true)
                {
                    bool hasNext;
                    try
                    {
                        hasNext = enumerator.MoveNext();
                    }
                    catch (UnauthorizedAccessException)
                    {
                        yield break;
                    }
                    catch (PathTooLongException)
                    {
                        yield break;
                    }
                    catch (IOException)
                    {
                        yield break;
                    }

                    if (!hasNext)
                    {
                        yield break;
                    }

                    yield return enumerator.Current;
                }
            }
        }
    }

    internal static class TextFileReader
    {
        public static bool TryReadAllLines(string filePath, out string[] lines, out string error)
        {
            lines = Array.Empty<string>();
            error = string.Empty;

            if (IsLikelyBinary(filePath))
            {
                error = "binary file";
                return false;
            }

            try
            {
                lines = EncodeGit.Instance.ReadAllLines(filePath);
                return true;
            }
            catch (Exception ex)
            {
                error = ex.Message;
                return false;
            }
        }

        private static bool IsLikelyBinary(string filePath)
        {
            try
            {
                using (var stream = new FileStream(filePath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
                {
                    int sampleSize = (int)Math.Min(4096, stream.Length);
                    if (sampleSize <= 0)
                    {
                        return false;
                    }

                    byte[] sample = new byte[sampleSize];
                    int readCount = stream.Read(sample, 0, sampleSize);
                    if (readCount <= 0)
                    {
                        return false;
                    }

                    if (readCount >= 2)
                    {
                        bool utf16Bom = (sample[0] == 0xFF && sample[1] == 0xFE)
                            || (sample[0] == 0xFE && sample[1] == 0xFF);
                        if (utf16Bom)
                        {
                            return false;
                        }
                    }

                    for (int i = 0; i < readCount; i++)
                    {
                        if (sample[i] == 0)
                        {
                            return true;
                        }
                    }
                }
            }
            catch
            {
                return true;
            }

            return false;
        }
    }
}

namespace EncodeSpellCard
{
    public class EncodeGit
    {
        public static EncodeGit Instance = new EncodeGit();
        private static readonly Encoding Utf8 = new UTF8Encoding(false, true);
        private static readonly Encoding Gb18030 = Encoding.GetEncoding("GB18030");

        public Encoding GetFileEncodeType(string filepath)
        {
            using (FileStream fs = new FileStream(filepath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
            {
                return GetTypes(fs);
            }
        }

        public StreamReader CreateReader(string filepath)
        {
            Encoding encoding = GetFileEncodeType(filepath);
            FileStream stream = new FileStream(filepath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite);

            try
            {
                return new StreamReader(stream, encoding, true);
            }
            catch
            {
                stream.Dispose();
                throw;
            }
        }

        public string[] ReadAllLines(string filepath)
        {
            var allLines = new List<string>();

            using (StreamReader reader = CreateReader(filepath))
            {
                string line;
                while ((line = reader.ReadLine()) != null)
                {
                    allLines.Add(line);
                }
            }

            return allLines.ToArray();
        }

        public static Encoding GetTypes(FileStream fs)
        {
            if (fs == null)
            {
                // NOTE: nameof() is C# 6; CodeDom on PS 5.1 stops at C# 5 -> use a string literal.
                throw new ArgumentNullException("fs");
            }

            long originalPosition = fs.CanSeek ? fs.Position : 0;

            try
            {
                if (fs.CanSeek)
                {
                    fs.Position = 0;
                }

                using (BinaryReader reader = new BinaryReader(fs, Encoding.Default, true))
                {
                    int length = checked((int)fs.Length);
                    if (length == 0)
                    {
                        return Utf8;
                    }

                    byte[] data = reader.ReadBytes(length);
                    return DetectEncoding(data);
                }
            }
            finally
            {
                if (fs.CanSeek)
                {
                    fs.Position = originalPosition;
                }
            }
        }

        private static Encoding DetectEncoding(byte[] data)
        {
            if (data == null || data.Length == 0)
            {
                return Utf8;
            }

            if (HasPrefix(data, 0xEF, 0xBB, 0xBF))
            {
                return Utf8;
            }

            if (HasPrefix(data, 0xFF, 0xFE, 0x00, 0x00))
            {
                return Encoding.UTF32;
            }

            if (HasPrefix(data, 0x00, 0x00, 0xFE, 0xFF))
            {
                return new UTF32Encoding(true, true);
            }

            if (HasPrefix(data, 0xFF, 0xFE))
            {
                return Encoding.Unicode;
            }

            if (HasPrefix(data, 0xFE, 0xFF))
            {
                return Encoding.BigEndianUnicode;
            }

            if (IsUTF8Bytes(data))
            {
                return Utf8;
            }

            return Gb18030;
        }

        private static bool HasPrefix(byte[] data, params byte[] prefix)
        {
            if (data.Length < prefix.Length)
            {
                return false;
            }

            for (int i = 0; i < prefix.Length; i++)
            {
                if (data[i] != prefix[i])
                {
                    return false;
                }
            }

            return true;
        }

        private static bool IsUTF8Bytes(byte[] data)
        {
            int charByteCounter = 1;
            byte curByte;
            for (int i = 0; i < data.Length; i++)
            {
                curByte = data[i];
                if (charByteCounter == 1)
                {
                    if (curByte >= 0x80)
                    {
                        while (((curByte <<= 1) & 0x80) != 0)
                        {
                            charByteCounter++;
                        }
                        if (charByteCounter == 1 || charByteCounter > 6)
                        {
                            return false;
                        }
                    }
                }
                else
                {
                    if ((curByte & 0xC0) != 0x80)
                    {
                        return false;
                    }
                    charByteCounter--;
                }
            }
            if (charByteCounter > 1)
            {
                throw new Exception("non-expected byte format");
            }
            return true;
        }
    }
}
'@
    try {
        Add-Type -TypeDefinition $csharp -Language CSharp
    } catch {
        [Console]::Error.WriteLine("fastsearch.ps1: failed to compile embedded C# source: $($_.Exception.Message)")
        exit 2
    }
}

# === EXTENSION POINT ==========================================================
# Default-on improvement over fastsearch.exe: force UTF-8 on stdout so redirected
# output is read cleanly by UTF-8 tools (Read/Grep) regardless of the OS code page
# (this is exactly what SKILL.md section 8 already assumes). Set FS_NO_UTF8=1 to
# revert to the legacy console-code-page behaviour of the original exe.
if (-not $env:FS_NO_UTF8) {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
}

# Other future polish goes here without touching the C# above, e.g. echo args:
#   if ($env:FS_ECHO) { [Console]::Error.WriteLine("fastsearch args: $($args -join ' | ')") }
# ==============================================================================

$rc = [fastsearch.Program]::Main([string[]]$args)
exit $rc
