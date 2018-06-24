module rvm.vm;
import std.algorithm, std.string, std.array, std.range, std.regex, std.stdio;
import rvm.instructions, rvm.utils;

struct Registers {
  int a;
  int b;
  int c;
  int d;
  int e;
  int f;
}

enum Register {
  A,
  B,
  C,
  D,
  E,
  F
}

Stack!int stack;
Registers registers;
Instruction[][int] functions;

static this() {
  stack = new Stack!int();
}

void setRegister(Register r, int v) {
  final switch (r) with (Register) {
  case A:
    registers.a = v;
    break;
  case B:
    registers.b = v;
    break;
  case C:
    registers.c = v;
    break;
  case D:
    registers.d = v;
    break;
  case E:
    registers.e = v;
    break;
  case F:
    registers.f = v;
    break;
  }
}

int getRegister(Register r) {
  final switch (r) with (Register) {
  case A:
    return registers.a;
  case B:
    return registers.b;
  case C:
    return registers.c;
  case D:
    return registers.d;
  case E:
    return registers.e;
  case F:
    return registers.f;
  }
}

void popTo(Stack!int stack, Register r) {
  if (stack.empty) {
    setRegister(r, 0);
  }
  else {
    int x = stack.pop;
    setRegister(r, x);
  }
}

void reduceStack(Stack!int stack, int result, int function(int, int) f) {
  if (stack.empty) {
    stack.push(result);
  }
  else {
    int x = stack.pop;
    reduceStack(stack, f(result, x), f);
  }
}

void saveFunction(int id, Instruction[] insts) {
  functions[id] = insts;
}

Instruction[] getFunction(int id) {
  return functions[id];
}

/*
  関数を呼ぶ場合，
  F -> 第1引数
  E -> 第2引数
  D -> 第3引数
  C -> 第4引数
*/

void setArgs(int[] args) {
  with (Register) {
    enum rs = [F, E, D, C];
    foreach (i, v; args) {
      setRegister(rs[i], v);
    }
  }
}

void compOpR2(T, alias pred)(Instruction inst) {
  T v = cast(T)inst;
  Register x = v.r1, y = v.r2;
  if (pred(getRegister(x), getRegister(y))) {
    setRegister(Register.B, 1);
  }
  else {
    setRegister(Register.B, 0);
  }
}

void compOpRI(T, alias pred)(Instruction inst) {
  T v = cast(T)inst;
  Register x = v.r;
  int y = v.i;
  if (pred(getRegister(x), y)) {
    setRegister(Register.B, 1);
  }
  else {
    setRegister(Register.B, 0);
  }
}

void arithmaticOpR2(T, alias pred)(Instruction inst) {
  T v = cast(T)inst;
  Register x = v.r1, y = v.r2;
  setRegister(Register.A, pred(getRegister(x), getRegister(y)));
}

void arithmaticOpRI(T, alias pred)(Instruction inst) {
  T v = cast(T)inst;
  Register x = v.r;
  int y = v.i;
  setRegister(Register.A, pred(getRegister(x), y));
}

void run(Instruction[] prog) {
  if (prog.empty) {
    //writeln("No more instruction");
  }
  else {
    Instruction inst = prog[0];
    Instruction[] rest = prog[1 .. $];

    final switch (inst.type) {
    case InstructionType.Func:
      Func func = cast(Func)inst;
      int id = func.id;
      Instruction[] proc = func.proc;
      saveFunction(id, proc);
      run(rest);
      break;
    case InstructionType.CallF:
      CallF callf = cast(CallF)inst;
      int id = callf.id;
      getFunction(id).run;
      run(rest);
      break;
    case InstructionType.CallFA:
      CallFA callfa = cast(CallFA)inst;
      int id = callfa.id;
      int[] args = callfa.args;
      setArgs(args);
      getFunction(id).run;
      run(rest);
      break;
    case InstructionType.CallFAR:
      CallFAR callfar = cast(CallFAR)inst;
      int id = callfar.id;
      Register[] args = callfar.args;
      args.map!(x => getRegister(x)).array.setArgs;
      getFunction(id).run;
      run(rest);
      break;
    case InstructionType.HLT:
      writeln("execution stopped");
      break;
    case InstructionType.Print:
      Print print = cast(Print)inst;
      Register r = print.r;
      writefln("%s : %d", r, getRegister(r));
      run(rest);
      break;
    case InstructionType.Eq:
      compOpR2!(Eq, ((int x, int y) => x == y))(inst);
      run(rest);
      break;
    case InstructionType.Neq:
      compOpR2!(Neq, ((int x, int y) => x != y))(inst);
      run(rest);
      break;
    case InstructionType.Leq:
      compOpR2!(Leq, ((int x, int y) => x <= y))(inst);
      run(rest);
      break;
    case InstructionType.Geq:
      compOpR2!(Geq, ((int x, int y) => x >= y))(inst);
      run(rest);
      break;
    case InstructionType.Lt:
      compOpR2!(Lt, ((int x, int y) => x < y))(inst);
      run(rest);
      break;
    case InstructionType.Gt:
      compOpR2!(Lt, ((int x, int y) => x > y))(inst);
      run(rest);
      break;
    case InstructionType.EqI:
      compOpRI!(EqI, ((int x, int y) => x == y))(inst);
      run(rest);
      break;
    case InstructionType.NeqI:
      compOpRI!(NeqI, ((int x, int y) => x != y))(inst);
      run(rest);
      break;
    case InstructionType.LeqI:
      compOpRI!(LeqI, ((int x, int y) => x <= y))(inst);
      run(rest);
      break;
    case InstructionType.GeqI:
      compOpRI!(GeqI, ((int x, int y) => x >= y))(inst);
      run(rest);
      break;
    case InstructionType.LtI:
      compOpRI!(LtI, ((int x, int y) => x < y))(inst);
      run(rest);
      break;
    case InstructionType.GtI:
      compOpRI!(GtI, ((int x, int y) => x > y))(inst);
      run(rest);
      break;
    case InstructionType.If:
      If _if = cast(If)inst;
      Register r = _if.r;
      Instruction[][] insts = _if.insts;

      if (getRegister(r) == 1) {
        run(insts[0]);
      }
      else if (insts.length == 2) {
        run(insts[1]);
      }
      run(rest);
      break;
    case InstructionType.RetR:
      RetR retr = cast(RetR)inst;
      Register x = retr.r;
      setRegister(Register.A, (getRegister(x)));
      run(rest);
      break;
    case InstructionType.RetI:
      RetI reti = cast(RetI)inst;
      int x = reti.i;
      setRegister(Register.A, x);
      run(rest);
      break;
    case InstructionType.AddR:
      arithmaticOpR2!(AddR, ((int x, int y) => x + y))(inst);
      run(rest);
      break;
    case InstructionType.AddI:
      arithmaticOpRI!(AddI, ((int x, int y) => x + y))(inst);
      run(rest);
      break;
    case InstructionType.SubR:
      arithmaticOpR2!(SubR, ((int x, int y) => x - y))(inst);
      run(rest);
      break;
    case InstructionType.SubI:
      arithmaticOpRI!(SubI, ((int x, int y) => x - y))(inst);
      run(rest);
      break;
    case InstructionType.MulR:
      arithmaticOpR2!(MulR, ((int x, int y) => x * y))(inst);
      run(rest);
      break;
    case InstructionType.MulI:
      arithmaticOpRI!(MulI, ((int x, int y) => x * y))(inst);
      run(rest);
      break;
    case InstructionType.MovR:
      MovR movr = cast(MovR)inst;
      Register x = movr.r1, y = movr.r2;
      setRegister(x, getRegister(y));
      run(rest);
      break;
    case InstructionType.MovI:
      MovI movi = cast(MovI)inst;
      Register x = movi.r;
      int y = movi.i;
      setRegister(x, y);
      run(rest);
      break;
    case InstructionType.PopTo:
      PopTo popto = cast(PopTo)inst;
      Register r = popto.r;
      popTo(stack, r);
      run(rest);
      break;
    case InstructionType.PushR:
      PushR pr = cast(PushR)inst;
      stack.push(getRegister(pr.r));
      run(rest);
      break;
    case InstructionType.PushI:
      PushI pi = cast(PushI)inst;
      stack.push(pi.i);
      run(rest);
      break;
    }
  }
}
