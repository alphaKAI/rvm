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
    this.stack.length = capacity;
  }

  typeof(this) dup() {
    typeof(this) newStack = new typeof(this)(this.capacity);

    with (newStack) {
      count = this.count;
      stack = this.stack.dup;
      capacity = this.capacity;
    }

    return newStack;
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
    if (count > capacity - (capacity / 8)) {
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
