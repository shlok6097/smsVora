import 'package:flutter/services.dart';

class BertTokenizer {
  final Map<String, int> vocab;
  final int maxSeqLength;

  static const String padToken = '[PAD]';
  static const String unkToken = '[UNK]';
  static const String clsToken = '[CLS]';
  static const String sepToken = '[SEP]';

  BertTokenizer({
    required this.vocab,
    this.maxSeqLength = 128,
  });

  static Future<BertTokenizer> fromAsset(String assetPath, {int maxSeqLength = 128}) async {
    final vocabString = await rootBundle.loadString(assetPath);
    final lines = vocabString.split('\n');
    final Map<String, int> vocabMap = {};
    for (int i = 0; i < lines.length; i++) {
      final token = lines[i].trim();
      if (token.isNotEmpty) {
        vocabMap[token] = i;
      }
    }
    return BertTokenizer(vocab: vocabMap, maxSeqLength: maxSeqLength);
  }

  /// Tokenizes a single text string into BERT inputs.
  /// Returns a map with 'input_ids', 'attention_mask', and 'token_type_ids'.
  Map<String, List<int>> encode(String text) {
    final tokens = _tokenize(text.toLowerCase());

    final List<String> truncated = tokens.length > (maxSeqLength - 2)
        ? tokens.sublist(0, maxSeqLength - 2)
        : tokens;

    final List<int> inputIds = [];
    final List<int> attentionMask = [];
    final List<int> tokenTypeIds = [];

    // [CLS]
    inputIds.add(vocab[clsToken] ?? 101);
    attentionMask.add(1);
    tokenTypeIds.add(0);

    for (final token in truncated) {
      inputIds.add(vocab[token] ?? vocab[unkToken] ?? 100);
      attentionMask.add(1);
      tokenTypeIds.add(0);
    }

    // [SEP]
    inputIds.add(vocab[sepToken] ?? 102);
    attentionMask.add(1);
    tokenTypeIds.add(0);

    // [PAD] to maxSeqLength
    final padId = vocab[padToken] ?? 0;
    while (inputIds.length < maxSeqLength) {
      inputIds.add(padId);
      attentionMask.add(0);
      tokenTypeIds.add(0);
    }

    return {
      'input_ids': inputIds,
      'attention_mask': attentionMask,
      'token_type_ids': tokenTypeIds,
    };
  }

  List<String> _tokenize(String text) {
    final words = _basicTokenize(text);
    final List<String> outputTokens = [];

    for (final word in words) {
      final subTokens = _wordPieceTokenize(word);
      outputTokens.addAll(subTokens);
    }

    return outputTokens;
  }

  List<String> _basicTokenize(String text) {
    final clean = text.replaceAll(RegExp(r'[\r\n\t]+'), ' ');
    final regex = RegExp(r'([a-zA-Z0-9]+|[^\s\w])');
    final matches = regex.allMatches(clean);
    return matches.map((m) => m.group(0)!).toList();
  }

  List<String> _wordPieceTokenize(String word) {
    if (word.length > 100) {
      return [unkToken];
    }

    final List<String> subTokens = [];
    int start = 0;

    while (start < word.length) {
      int end = word.length;
      String? curSubStr;

      while (start < end) {
        String sub = word.substring(start, end);
        if (start > 0) {
          sub = '##$sub';
        }
        if (vocab.containsKey(sub)) {
          curSubStr = sub;
          break;
        }
        end--;
      }

      if (curSubStr == null) {
        return [unkToken];
      }

      subTokens.add(curSubStr);
      start = end;
    }

    return subTokens;
  }
}
