import 'package:flutter_test/flutter_test.dart';

import 'package:coworking_app/models/sala.dart';

void main() {
  test('Sala.copyWith atualiza apenas os campos informados', () {
    const original = Sala(id: 1, nome: 'Sala Azul');
    final updated = original.copyWith(nome: 'Sala Verde');

    expect(updated.id, 1);
    expect(updated.nome, 'Sala Verde');
  });
}
