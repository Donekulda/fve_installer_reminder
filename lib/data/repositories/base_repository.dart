abstract class BaseRepository<T> {
  Future<T?> getById(int id);
  Future<List<T>> getAll();
  Future<void> create(T entity);
  Future<void> update(T entity);
  Future<void> delete(int id);
}
