class Data{
	friend class Operation;
	friend int main();
  private:
	unsigned int x[2];
	void read();
	void print()const;
  public:
  Data(){clr();}
	void add_eq(const Data &a);
	void add(const Data &a,const Data &b);
	void clr();
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
	const int p[],
	const Data d[],
	const int x1[],
	const int x2[],
	const int y1[],
	const int y2[],
	const Operation o[][3][3],
	Data ans[][3][3]);

