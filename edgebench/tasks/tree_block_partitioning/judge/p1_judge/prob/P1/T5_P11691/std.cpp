#include "data.h"

#include<bits/stdc++.h>

#define F(i,l,r) for(int i=l;i<r;++i)
#define Fe(i,l,r) for(int i=l;i<=r;++i)

#define pr(...) void(0) //fprintf(stderr,__VA_ARGS__)

typedef long long i64;

using std::swap;
using std::sort;

const int B=1007,N=500007;

int n,q,cur_x;

//禁止竖直线，三线共点，直线重合。

bool rev[B];
struct Line{
	//ax+by<c
	int a,b,c,id;//|a|,|b|<=1000; b!=0; |c|<=1000000
	bool operator<(const Line& w)const{
		int k1=a*w.b-b*w.a;
		if(k1)return k1<0;
		return c*w.b-b*w.c<0;
	}
	void init(int x){
		assert(b);
		rev[x]=(b<0);
		if(b<0)a=-a,b=-b,c=-c;
		id=x;
	}
}ls[B],ls0[N];
int lp0=0;

struct Cmp{
	bool operator()(const Line &w,const Line &u){
		int w1=w.c-w.a*cur_x,w2=w.b;
		int u1=u.c-u.a*cur_x,u2=u.b;
		return w1*u2<u1*w2;
	}
};

struct node{
	node*l,*r,*p;
	int u,d;
	void init(int w){
		l=r=p=0;
		u=w;
		d=w+1;
	}
	void lk(node*w,node*u){
		w->r=this;
		l=w;r=0;p=u;
	}
}ns[B*B],*n0[B],*n1[B];
int np;
int pos[B],pos0[B];

void merge(int x,int y);

void del(int L,int R){
	F(i,L,R){
		node *w=n1[pos0[i]];
		for(;w;w=w->r){
			merge(w->u,w->d);
			node *u=w->p;
			if(u){
				node *v=u->l->r=u->r;
				if(v)v->l=u->l;
			}
		}
	}
}

void ins(int L,int R){
	for(int i=R-1;i>=L;--i){
		node *w=n1[pos0[i]];
		for(;w;w=w->r){
			node *u=w->p;
			if(u){
				u->l->r=u;
				node *v=u->r;
				if(v)v->l=u;
			}
		}
	}
}

struct Cross{
	int x1,x2;//x=x2/x1
	int w1,w2,key2;
	bool operator<(const Cross& c)const{
		i64 s=i64(x2)*c.x1-i64(x1)*c.x2;
		return s?s<0:key2<c.key2;
	}
	int init(Line &l1,Line &l2,int c){
		x1=l1.a*l2.b-l2.a*l1.b;
		if(!x1)return 0;
		x2=l1.c*l2.b-l1.b*l2.c;
		if(x1<0)x1=-x1,x2=-x2;
		w1=l1.id;
		w2=l2.id;
		key2=c;
		return 1;
	}
}cs[B*B];
int cp=0;

Data s1[N],s2[N];
int tB;
Data *ans;
std::vector<std::pair<int,int>> ms[N];
Data _sum(int x){
	Data s;
	s.clr();
	int x2=(x-1)/tB;
	F(i,0,x2)s.add(s,s2[i]);
	Fe(i,x2*tB+1,x)s.add(s,s1[i]);
	return s;
}


struct Tag{
	int t;
	void del(const Data &d)const{
		assert(t);
		int t2=(t-1)/tB;
		s1[t].sub(s1[t],d);
		s2[t2].sub(s2[t2],d);
	}
	void ins(const Data &d)const{
		assert(t);
		int t2=(t-1)/tB;
		s1[t].add(s1[t],d);
		s2[t2].add(s2[t2],d);
	}
	void clr(){t=0;}
	operator bool()const{return t;}
};

struct Pos{
	int x,y;
	Data d;
	Tag t0;
	Tag *t;
	Pos *p0;
	void init(){
		t0=Tag{1};
		t=0;
	}
	bool operator<(const Pos &w)const{return x<w.x;}
	bool operator<(const Cross &w)const{return x*i64(w.x1)<w.x2;}
}ps[N];

struct DSU{
	int f,v;
}dsu[B*B];

struct node2;
node2*d_useful;
struct node2{
	node2*lc,*rc;
	Pos *p0;
	Data d;
	Tag t;
	void init(){
		lc=rc=0;
		p0=0;
		d.clr();
		t.clr();
	}
	void init(Pos &p){
		d.add(d,p.d);
		p.t=&t;
		p.p0=p0;
		p0=&p;
	}
	void init(node2*l,node2*r){
		lc=l;rc=r;
		p0=0;
		d.add(l->d,r->d);
		t.clr();
	}
	void dfs(){
		if(t){
			t.del(d);
			t.clr();
			return;
		}
		if(lc){
			lc->dfs();
			rc->dfs();
		}else{
			for(Pos *p=p0;p;p=p->p0){
				p->t0.del(p->d);
				p->t0.clr();
			}
		}
	}
	void apply(const Tag &w){
		dfs();
		t=w;
		t.ins(d);
	}
	void destroy()const{
		if(t){
			lc->t=t;
			rc->t=t;
		}
	}
}ns2[B*B*2];
int np2;

struct Op{
	int *x,y;
	void undo(){*x=y;}
}ops[B*B*3];
int opp=0;

void _set(int &x,int y){
	ops[opp++]=Op{&x,x};
	x=y;
}
struct Undo{
	int p,p2;
	Undo():p(opp),p2(np2){}
	~Undo(){
		d_useful=ns2+p2;
		while(np2>p2)ns2[--np2].destroy();
		while(opp>p)ops[--opp].undo();
	}
};

int find(int x){
	while(dsu[x].f>=0)x=dsu[x].f;
	return x;
}
void merge(int x,int y){
	x=find(x);
	y=find(y);
	assert(x!=y);
	int &nx=dsu[x].v,&ny=dsu[y].v;
	ns2[np2].init(ns2+nx,ns2+ny);
	int &hx=dsu[x].f,&hy=dsu[y].f;
	if(hx==hy)_set(hx,y),_set(hy,hy-1),_set(ny,np2);
	else if(hx>hy)_set(hx,y),_set(ny,np2);
	else _set(hy,x),_set(nx,np2);
	++np2;
}

int tk=1;

void dc(int L,int R){
	if(R-L==1){
		bool tp=rev[L];
		int id=find(tp?n1[pos0[L]]->d:n1[pos0[L]]->u);
		id=dsu[id].v;
		d_useful=ns2+np2;
		ns2[id].apply(Tag{++tk});
		for(auto m:ms[tk]){
			ans[m.second]=_sum(m.first);
		}
		return;
	}
	int M=(L+R)>>1;
	{Undo _;del(M,R);dc(L,M);ins(M,R);}
	del(L,M);dc(M,R);ins(L,M);
}

void calc(int m){
	F(i,0,m){
		ls[i]=ls0[lp0++];
		ls[i].init(i);
	}
	
	sort(ls,ls+m);
	F(i,0,m)pos[ls[i].id]=i;
	F(i,0,m)pos0[i]=pos[i];
	
	cp=0;
	F(i,0,m)F(j,0,i)cp+=cs[cp].init(ls[i],ls[j],i*B+j);
	
	sort(cs,cs+cp);
	
	np=0;np2=m+1;
	F(i,0,m){
		n1[i]=n0[i]=ns+np;
		ns[np++].init(i);
	}
	F(i,0,np2)ns2[i].init();
	int p=0;
	for(int i=0;;++i){
		for(;p<n&&(i==cp||ps[p]<cs[i]);++p){
			cur_x=ps[p].x;
			Line w{0,1,ps[p].y,0};
			int p1=std::lower_bound(ls,ls+m,w,Cmp())-ls,ans;
			if(p1==m)ans=n0[m-1]->d;
			else ans=n0[p1]->u;
			ns2[ans].init(ps[p]);
		}
		if(i==cp)break;
		int id1=cs[i].w1;
		int id2=cs[i].w2;
		int &p1=pos[id1];
		int &p2=pos[id2];
		
		assert(std::abs(p1-p2)==1);
		swap(ls[p1],ls[p2]);
		
		node *w1=n0[p1],*w2=n0[p2];
		node *w3=ns+np++;
		node *w4=ns+np++;
		w3->lk(w1,w4);
		w4->lk(w2,w3);
		n0[p1]=w4;
		n0[p2]=w3;
		if(w1->d!=w2->u)swap(w1,w2),swap(w3,w4);
		w4->u=w1->u;
		w3->d=w2->d;
		ns2[np2].init();
		w4->d=w3->u=np2++;
		
		swap(p1,p2);
	}
	
	F(i,0,np2)dsu[i]=DSU{-1,i};
	
	{Undo _;dc(0,m);}
	
	F(i,0,n)if(*ps[i].t)ps[i].t0=*ps[i].t;
}

void solve(
	int _n,
	int _xy[][2],
	Data _d[],
	int _m,
	int _abc[][3],
	int _q,
	int _lr[][2],
	Data _ans[]){
		
	n=_n;
	F(i,0,n){
		ps[i].x=_xy[i+1][0];
		ps[i].y=_xy[i+1][1];
		ps[i].d=_d[i+1];
		ps[i].init();
	}
	sort(ps,ps+n);
	
	q=_m;
	F(i,0,q){
		ls0[i].a=_abc[i+1][0];
		ls0[i].b=_abc[i+1][1];
		ls0[i].c=_abc[i+1][2];
	}
	int m=_q;
	Fe(i,1,m){
		int l=_lr[i][0],r=_lr[i][1];
		ms[r+1].emplace_back(l,i);
	}
	ans=_ans;
	
	int B=(int)sqrt(n*0.64)+1;
	tB=sqrt(q);
	Fe(i,1,q+1)s1[i].clr();
	Fe(i,0,q/tB)s2[i].clr();
	F(i,0,n)ps[i].t0.ins(ps[i].d);
	//fprintf(stderr,">>> %d %d %d\n",(int)(q/B*(n+B*B*9/8)),(int)(q/B*(n+B*B)),(int)(q/B*(B*B)));
	while(q>0){
		int b=std::min(q,B);
		calc(b);
		q-=b;
	}
}
