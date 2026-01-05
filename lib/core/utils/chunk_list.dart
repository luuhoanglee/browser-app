class ChunkList {
  static List<List<T>> convert<T>(List<T> list, int size) {
    return List.generate(
      (list.length / size).ceil(),
          (index) => list.skip(index * size).take(size).toList(),
    );
  }

  static List<List<T>> transposeGrid<T>(List<T> list, int rowLength) {
    final rows = ChunkList.convert<T>(list, rowLength);

    if (rows.isEmpty) return [];

    final colLength = rows[0].length;

    return List.generate(colLength, (i) {
      return List.generate(rows.length, (j) {
        if (i >= rows[j].length) return null as T;
        return rows[j][i];
      });
    });
  }

}