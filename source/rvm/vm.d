module rvm.vm;
import std.algorithm, std.string, std.array, std.range, std.regex, std.stdio;
import rvm.instructions, rvm.utils;
import core.thread;

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
  F,
}

Thread[int] threads;
Frame[int] frames;

class Frame {
  Stack!int stack;
  Registers registers;
  Instruction[][int] functions;
  Instruction[] prog;

  this() {
    this.stack = new Stack!int();
  }

  this(Instruction[] prog) {
    this();
    this.prog = prog.dup;
  }

  void setProg(Instruction[] prog) {
    this.prog = prog.dup;
  }

  Frame dup() {
    Frame newFrame = new Frame;

    with (newFrame) {
      stack = this.stack.dup;
      registers = this.registers;
      functions = this.functions.dup;
      prog = this.prog.dup;
    }

    return newFrame;
  }
}

Frame genFrame() {
  return new Frame;
}

Frame genFrame(Instruction[] prog) {
  return new Frame(prog);
}

void setRegister(Frame frame, Register r, int v) {
  with (frame) final switch (r) with (Register) {
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

int getRegister(Frame frame, Register r) {
  with (frame) final switch (r) with (Register) {
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

void popTo(Frame frame, Stack!int stack, Register r) {
  if (stack.empty) {
    frame.setRegister(r, 0);
  }
  else {
    int x = stack.pop;
    frame.setRegister(r, x);
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

void saveFunction(Frame frame, int fid, Instruction[] insts) {
  with (frame)
    functions[fid] = insts;
}

Instruction[] getFunction(Frame frame, int fid) {
  with (frame)
    return functions[fid];
}

/*
  関数を呼ぶ場合，
  F -> 第1引数
  E -> 第2引数
  D -> 第3引数
  C -> 第4引数
*/

void setArgs(Frame frame, int[] args) {
  with (Register) {
    enum rs = [F, E, D, C];
    foreach (i, v; args) {
      frame.setRegister(rs[i], v);
    }
  }
}

void compOpR2(T, alias pred)(Frame frame, Instruction inst) {
  T v = cast(T)inst;
  Register x = v.r1, y = v.r2;
  if (pred(frame.getRegister(x), frame.getRegister(y))) {
    frame.setRegister(Register.B, 1);
  }
  else {
    frame.setRegister(Register.B, 0);
  }
}

void compOpRI(T, alias pred)(Frame frame, Instruction inst) {
  T v = cast(T)inst;
  Register x = v.r;
  int y = v.i;
  if (pred(frame.getRegister(x), y)) {
    frame.setRegister(Register.B, 1);
  }
  else {
    frame.setRegister(Register.B, 0);
  }
}

void arithmaticOpR2(T, alias pred)(Frame frame, Instruction inst) {
  T v = cast(T)inst;
  Register x = v.r1, y = v.r2;
  frame.setRegister(Register.A, pred(frame.getRegister(x), frame.getRegister(y)));
}

void arithmaticOpRI(T, alias pred)(Frame frame, Instruction inst) {
  T v = cast(T)inst;
  Register x = v.r;
  int y = v.i;
  frame.setRegister(Register.A, pred(frame.getRegister(x), y));
}

void run(Frame frame) {
  Instruction[] prog = frame.prog;
  frame.run(prog);
}

void run(Frame frame, Instruction[] prog) {
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
      frame.saveFunction(id, proc);
      break;
    case InstructionType.CallF:
      CallF callf = cast(CallF)inst;
      int id = callf.id;
      frame.run(frame.getFunction(id));
      break;
    case InstructionType.CallFA:
      CallFA callfa = cast(CallFA)inst;
      int id = callfa.id;
      int[] args = callfa.args;
      frame.setArgs(args);
      frame.run(frame.getFunction(id));
      break;
    case InstructionType.CallFAR:
      CallFAR callfar = cast(CallFAR)inst;
      int id = callfar.id;
      Register[] args = callfar.args;
      frame.setArgs(args.map!(x => frame.getRegister(x)).array);
      frame.run(frame.getFunction(id));
      break;
    case InstructionType.HLT:
      writeln("execution stopped");
      return;
    case InstructionType.Print:
      Print print = cast(Print)inst;
      Register r = print.r;
      writefln("%s : %d", r, frame.getRegister(r));
      break;
    case InstructionType.Eq:
      compOpR2!(Eq, ((int x, int y) => x == y))(frame, inst);
      break;
    case InstructionType.Neq:
      compOpR2!(Neq, ((int x, int y) => x != y))(frame, inst);
      break;
    case InstructionType.Leq:
      compOpR2!(Leq, ((int x, int y) => x <= y))(frame, inst);
      break;
    case InstructionType.Geq:
      compOpR2!(Geq, ((int x, int y) => x >= y))(frame, inst);
      break;
    case InstructionType.Lt:
      compOpR2!(Lt, ((int x, int y) => x < y))(frame, inst);
      break;
    case InstructionType.Gt:
      compOpR2!(Lt, ((int x, int y) => x > y))(frame, inst);
      break;
    case InstructionType.EqI:
      compOpRI!(EqI, ((int x, int y) => x == y))(frame, inst);
      break;
    case InstructionType.NeqI:
      compOpRI!(NeqI, ((int x, int y) => x != y))(frame, inst);
      break;
    case InstructionType.LeqI:
      compOpRI!(LeqI, ((int x, int y) => x <= y))(frame, inst);
      break;
    case InstructionType.GeqI:
      compOpRI!(GeqI, ((int x, int y) => x >= y))(frame, inst);
      break;
    case InstructionType.LtI:
      compOpRI!(LtI, ((int x, int y) => x < y))(frame, inst);
      break;
    case InstructionType.GtI:
      compOpRI!(GtI, ((int x, int y) => x > y))(frame, inst);
      break;
    case InstructionType.If:
      If _if = cast(If)inst;
      Register r = _if.r;
      Instruction[][] insts = _if.insts;

      if (frame.getRegister(r) == 1) {
        frame.run(insts[0]);
      }
      else if (insts.length == 2) {
        frame.run(insts[1]);
      }
      break;
    case InstructionType.RetR:
      RetR retr = cast(RetR)inst;
      Register x = retr.r;
      frame.setRegister(Register.A, (frame.getRegister(x)));
      break;
    case InstructionType.RetI:
      RetI reti = cast(RetI)inst;
      int x = reti.i;
      frame.setRegister(Register.A, x);
      break;
    case InstructionType.AddR:
      arithmaticOpR2!(AddR, ((int x, int y) => x + y))(frame, inst);
      break;
    case InstructionType.AddI:
      arithmaticOpRI!(AddI, ((int x, int y) => x + y))(frame, inst);
      break;
    case InstructionType.SubR:
      arithmaticOpR2!(SubR, ((int x, int y) => x - y))(frame, inst);
      break;
    case InstructionType.SubI:
      arithmaticOpRI!(SubI, ((int x, int y) => x - y))(frame, inst);
      break;
    case InstructionType.MulR:
      arithmaticOpR2!(MulR, ((int x, int y) => x * y))(frame, inst);
      break;
    case InstructionType.MulI:
      arithmaticOpRI!(MulI, ((int x, int y) => x * y))(frame, inst);
      break;
    case InstructionType.MovR:
      MovR movr = cast(MovR)inst;
      Register x = movr.r1, y = movr.r2;
      frame.setRegister(x, frame.getRegister(y));
      break;
    case InstructionType.MovI:
      MovI movi = cast(MovI)inst;
      Register x = movi.r;
      int y = movi.i;
      frame.setRegister(x, y);
      break;
    case InstructionType.PopTo:
      PopTo popto = cast(PopTo)inst;
      Register r = popto.r;
      frame.popTo(frame.stack, r);
      break;
    case InstructionType.PushR:
      PushR pr = cast(PushR)inst;
      frame.stack.push(frame.getRegister(pr.r));
      break;
    case InstructionType.PushI:
      PushI pi = cast(PushI)inst;
      frame.stack.push(pi.i);
      break;
    case InstructionType.MTh:
      MTh mth = cast(MTh)inst;
      int id = mth.id;
      Instruction[] _prog = mth.insts;
      Frame newFrame = frame.dup;
      newFrame.prog = _prog;
      frames[id] = newFrame;
      break;
    case InstructionType.RTh:
      RTh rth = cast(RTh)inst;
      int id = rth.id;
      threads[id] = new Thread(((Frame frame) => () { frame.run; })(frames[id])).start;
      break;
    case InstructionType.JTh:
      JTh jth = cast(JTh)inst;
      int id = jth.id;
      if (threads[id]!is null) {
        threads[id].join;
        threads[id] = null;
      }
      break;
    case InstructionType.SleepI:
      SleepI sleepi = cast(SleepI)inst;
      int msec = sleepi.msec;
      Thread.sleep(dur!"msecs"(msec));
      break;
    case InstructionType.Printsln:
      Printsln printsln = cast(Printsln)inst;
      string msg = printsln.msg;
      writeln(msg);
      break;
    }
    frame.run(rest);
  }
}
