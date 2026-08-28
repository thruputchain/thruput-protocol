enum Kind { A = 0 }; union Result switch (Kind kind) { case A: int value; default: void; }; program P { version P1 { Result call(void) = 1; } = 1; } = 0x1001;
