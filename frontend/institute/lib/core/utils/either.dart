import '../errors/failures.dart';

abstract class Either<L, R> {
  const Either();

  bool isLeft() => this is Left<L, R>;
  bool isRight() => this is Right<L, R>;

  L get left => (this as Left<L, R>).value;
  R get right => (this as Right<L, R>).value;

  T fold<T>(T Function(L) leftFunc, T Function(R) rightFunc) {
    if (isLeft()) {
      return leftFunc(left);
    } else {
      return rightFunc(right);
    }
  }
}

class Left<L, R> extends Either<L, R> {
  final L value;
  const Left(this.value);
}

class Right<L, R> extends Either<L, R> {
  final R value;
  const Right(this.value);
}

typedef EitherFailure<T> = Either<Failure, T>;