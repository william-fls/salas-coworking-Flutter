typedef ContainsMessageRule = MapEntry<String, String>;

class ContainsAllMessageRule {
  const ContainsAllMessageRule({
    required this.terms,
    required this.message,
  });

  final List<String> terms;
  final String message;
}

String mapMessageByRules(
  String raw, {
  required Iterable<ContainsMessageRule> containsRules,
  Iterable<ContainsAllMessageRule> containsAllRules = const [],
  String fallbackMessage = 'Ocorreu um erro inesperado.',
}) {
  for (final rule in containsAllRules) {
    if (rule.terms.every(raw.contains)) {
      return rule.message;
    }
  }

  for (final rule in containsRules) {
    if (raw.contains(rule.key)) {
      return rule.value;
    }
  }

  return fallbackMessage;
}
