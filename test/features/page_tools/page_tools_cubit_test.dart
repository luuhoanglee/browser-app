import 'package:browser_app/features/page_tools/bloc/page_tools_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('find results stay isolated by tab', () {
    final cubit = PageToolsCubit();
    addTearDown(cubit.close);

    cubit.updateFindResult('primary', 0, 3);
    cubit.updateFindResult('secondary', 1, 2);

    expect(cubit.state.resultFor('primary').activeMatch, 1);
    expect(cubit.state.resultFor('primary').matchCount, 3);
    expect(cubit.state.resultFor('secondary').activeMatch, 2);
    expect(cubit.state.resultFor('secondary').matchCount, 2);
  });
}
