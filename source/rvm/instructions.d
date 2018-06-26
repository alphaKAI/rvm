module rvm.instructions;
import rvm.vm;
import std.string;

enum InstructionType {
  Func,
  CallF,
  CallFA,
  CallFAR,
  HLT,
  Print,
  Eq,
  Neq,
  Leq,
  Geq,
  Lt,
  Gt,
  EqI,
  NeqI,
  LeqI,
  GeqI,
  LtI,
  GtI,
  If,
  RetR,
  RetI,
  AddR,
  AddI,
  SubR,
  SubI,
  MulR,
  MulI,
  MovR,
  MovI,
  PopTo,
  PushR,
  PushI,
  MTh,
  RTh,
  JTh,
  SleepI,
  Printsln
}

interface Instruction {
  InstructionType type();
}

class Func : Instruction {
  int id;
  Instruction[] proc;
  this(int id, Instruction[] proc) {
    this.id = id;
    this.proc = proc;
  }

  InstructionType type() {
    return InstructionType.Func;
  }
}

Instruction func(int id, Instruction[] proc) {
  return new Func(id, proc);
}

class CallF : Instruction {
  int id;
  this(int id) {
    this.id = id;
  }

  InstructionType type() {
    return InstructionType.CallF;
  }
}

Instruction callf(int id) {
  return new CallF(id);
}

class CallFA : Instruction {
  int id;
  int[] args;
  this(int id, int[] args) {
    this.id = id;
    this.args = args;
  }

  InstructionType type() {
    return InstructionType.CallFA;
  }
}

Instruction callfa(int id, int[] args) {
  return new CallFA(id, args);
}

class CallFAR : Instruction {
  int id;
  Register[] args;
  this(int id, Register[] args) {
    this.id = id;
    this.args = args;
  }

  InstructionType type() {
    return InstructionType.CallFAR;
  }
}

Instruction callfar(int id, Register[] args) {
  return new CallFAR(id, args);
}

class HLT : Instruction {
  InstructionType type() {
    return InstructionType.HLT;
  }
}

HLT hlt() {
  return new HLT;
}

string opR(string className)() {
  string helperName = className.toLower;
  return `
    class ` ~ className ~ ` : Instruction {
      Register r;
      this(Register r) {
        this.r = r;
      }

      InstructionType type() {
        return InstructionType.` ~ className ~ `;
      }
    }
    
    Instruction ` ~ helperName
    ~ `(Register r) {
      return new ` ~ className ~ `(r);
    }`;
}

string opI(string className)() {
  string helperName = className.toLower;
  return `
    class ` ~ className ~ ` : Instruction {
      int i;
      this(int i) {
        this.i = i;
      }

      InstructionType type() {
        return InstructionType.` ~ className ~ `;
      }
    }
    
    Instruction ` ~ helperName
    ~ `(int i) {
      return new ` ~ className ~ `(i);
    }`;
}

string opR2(string className)() {
  string helperName = className.toLower;
  return `
    class ` ~ className ~ ` : Instruction {
      Register r1, r2;
      this(Register r1, Register r2) {
        this.r1 = r1;
        this.r2 = r2;
      }

      InstructionType type() {
        return InstructionType.` ~ className ~ `;
      }
    }

    Instruction ` ~ helperName
    ~ `(Register r1, Register r2) {
      return new ` ~ className ~ `(r1, r2);
    }`;
}

string opRI(string className)() {
  string helperName = className.toLower;
  return `
    class ` ~ className ~ ` : Instruction {
      Register r;
      int i;
      this(Register r, int i) {
        this.r = r;
        this.i = i;
      }

      InstructionType type() {
        return InstructionType.` ~ className ~ `;
      }
    }
    
    Instruction ` ~ helperName
    ~ `(Register r, int i) {
      return new ` ~ className ~ `(r, i);
    }`;
}

mixin(opR!("Print"));
mixin(opR2!("Eq"));
mixin(opR2!("Neq"));
mixin(opR2!("Leq"));
mixin(opR2!("Geq"));
mixin(opR2!("Lt"));
mixin(opR2!("Gt"));
mixin(opRI!("EqI"));
mixin(opRI!("NeqI"));
mixin(opRI!("LeqI"));
mixin(opRI!("GeqI"));
mixin(opRI!("LtI"));
mixin(opRI!("GtI"));

class If : Instruction {
  Register r;
  Instruction[][] insts;
  this(Register r, Instruction[][] insts) {
    this.r = r;
    this.insts = insts;
  }

  InstructionType type() {
    return InstructionType.If;
  }
}

Instruction _if(Register r, Instruction[][] insts) {
  return new If(r, insts);
}

mixin(opR!("RetR"));
mixin(opI!("RetI"));
mixin(opR2!("AddR"));
mixin(opRI!("AddI"));
mixin(opR2!("SubR"));
mixin(opRI!("SubI"));
mixin(opR2!("MulR"));
mixin(opRI!("MulI"));
mixin(opR2!("MovR"));
mixin(opRI!("MovI"));
mixin(opR!("PopTo"));
mixin(opR!("PushR"));
mixin(opI!("PushI"));

class MTh : Instruction {
  int id;
  Instruction[] insts;
  this(int id, Instruction[] insts) {
    this.id = id;
    this.insts = insts;
  }

  InstructionType type() {
    return InstructionType.MTh;
  }
}

Instruction mth(int id, Instruction[] insts) {
  return new MTh(id, insts);
}

class RTh : Instruction {
  int id;
  this(int id) {
    this.id = id;
  }

  InstructionType type() {
    return InstructionType.RTh;
  }
}

Instruction rth(int id) {
  return new RTh(id);
}

class JTh : Instruction {
  int id;
  this(int id) {
    this.id = id;
  }

  InstructionType type() {
    return InstructionType.JTh;
  }
}

Instruction jth(int id) {
  return new JTh(id);
}

class SleepI : Instruction {
  int msec;
  this(int msec) {
    this.msec = msec;
  }

  InstructionType type() {
    return InstructionType.SleepI;
  }
}

Instruction sleepi(int msec) {
  return new SleepI(msec);
}

class Printsln : Instruction {
  string msg;
  this(string msg) {
    this.msg = msg;
  }

  InstructionType type() {
    return InstructionType.Printsln;
  }
}

Instruction printsln(string msg) {
  return new Printsln(msg);
}
