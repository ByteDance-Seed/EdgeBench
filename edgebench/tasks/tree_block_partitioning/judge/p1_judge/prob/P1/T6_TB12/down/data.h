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
	int n,
	int m,
	int fa[],
	Data d0[],
	int x[],
	int y[],
	Operation o[][2],
	Data ans[][2]);

