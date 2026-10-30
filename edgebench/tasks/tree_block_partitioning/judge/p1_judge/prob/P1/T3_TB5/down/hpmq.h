class Data{
	friend class Operation;
	friend int main();
  private:
	unsigned int x[2];
	void read();
  public:
  Data(){clr();}
	void add_eq(const Data &a);
	void add(const Data &a,const Data &b);
	void clr();
	void print()const;
	bool empty()const;
};

class Operation{
	friend int main();
  private:
	unsigned int a[2][2];
	void read();
  public:
  Operation(){clr();}
	void apply(Data &w)const;
	void apply(Operation &w)const;
	void clr();
	bool empty()const;
};

void solve(
	const int n,
	const int m,
	const int *x,
	const int *y,
	const Data *d,
	const int *a,
	const int *b,
	const int *c,
	const Operation *o);
