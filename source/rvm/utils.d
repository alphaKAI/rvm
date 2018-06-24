module rvm.utils;
import std.array;

class Stack(T) {
  T[] stack;
  size_t count;
  size_t capacity;
  enum DEFAULT_SIZE = 1024;

  this() {
    this(DEFAULT_SIZE);
  }

  this(size_t capacity) {
    this.capacity = capacity;
    stack.length = capacity;
  }

  @property T pop() {
    if (count == 0) {
      throw new Error("Stack is Empty");
    }
    else {
      return stack[count-- - 1];
    }
  }

  @property size_t length() {
    return count;
  }

  @property void push(T value) {
    if (capacity - count + 1 < capacity / 4) {
      // resize
      stack.length += capacity;
    }
    stack[count++] = value;
  }

  @property bool empty() {
    return count == 0;
  }

  @property T front() {
    return pop;
  }

  @property void popFront() {
    pop;
  }

  @property void popAll() {
    foreach (_; this) {
    }
  }
}
