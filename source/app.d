import rvm.instructions, rvm.vm;

void main() {
	/*
  Func#1 is the same as
  let rec fact n =
    if n = 0 then 1
    else
      let m = n - 1 in
      let k = fact m in
      return n * k;;
  
  [
    func(1, [
      eqi(F, 0),
      _if(B, [[
        reti(1)
      ], [
        subi(F, 1),
        movr(D, A),
        pushr(F),
        callfar(1, [D]),
        popto(E),
        mulr(E, A),
        retr(A)]
      ])
    ]),
    callfa(1, [10]),
    print(A)
  ]

	Func#2 is the same as
	let rec fib n =
		if n <= 1 then
			n
		else
			let k1 = n - 2 in
			let r1 = fib k1 in
			let k2 = n - 1 in
			ret r2 = fib k2 in
			r1 + r2

		[func(2, [
			print(F),
			leqi(F, 1),
			_if(B, [[
				retr(F)
			], [
				subi(F, 2),
				movr(C, A),
				pushr(F),
				callfar(2, [C]),
				movr(C, A),
				popto(F),
				subi(F, 1),
				movr(D, A),
				pushr(C),
				callfar(2, [D]),
				popto(C),
				movr(D, A),
				addr(C, D),
				retr(A)
			]])
		]),
		callfa(2, [5]),
		print(A)]
*/

	/*
	Multi Thread Code
		let rec f1 n k =
			if k = n then
				0
			else
				sleep 1000
				printsln
				f1 n (k + 1)

[
	mth(1, [
		func(1, [
			eq(F, E),
			_if(B, [[
					reti(0)
				],[
					sleepi(1000),
					printsln("thread1"),
					addi(E, 1),
					movr(E, A),
					callfar(1, [F, E])
				]])
		]),
		callfar(1, [10, 0])
	]),
	mth(2, [
		func(1, [
			eq(F, E),
			_if(B, [[
					reti(0)
				],[
					sleepi(200),
					printsln("thread2"),
					addi(E, 1),
					movr(E, A),
					callfar(1, [F, E])
				]])
		]),
		callfar(1, [50, 0])
	]),
	rth(1),
	rth(2),
	jth(1),
	jth(2)
]
*/

	with (Register) {
		/*
		Instruction[] program = [func(1, [eqi(F, 0), _if(B, [[reti(1)], [subi(F,
				1), movr(D, A), pushr(F), callfar(1, [D]), popto(E), mulr(E, A), retr(A)]])]),
			callfa(1, [10]), print(A)];
			*/
		/*
		Instruction[] program = [func(2, [leqi(F, 1), _if(B, [[retr(F)], [subi(F,
				2), movr(C, A), pushr(F), callfar(2, [C]), movr(C, A), popto(F),
				subi(F, 1), movr(D, A), pushr(C), callfar(2, [D]), popto(C), movr(D,
				A), addr(C, D), retr(A)]])]), callfa(2, [35]), print(A)];
				*/
		Instruction[] program = [mth(1, [func(1, [eq(F, E), _if(B, [[reti(0)],
				[sleepi(1000), printsln("thread1"), addi(E, 1), movr(E, A), callfar(1, [F, E])]])]),
				callfa(1, [10, 0])]), mth(2, [func(1, [eq(F, E), _if(B, [[reti(0)],
				[sleepi(200), printsln("thread2"), addi(E, 1), movr(E, A), callfar(1, [F, E])]])]),
				callfa(1, [50, 0])]), rth(1), rth(2), jth(1), jth(2)];
		genFrame.run(program);
	}
}
