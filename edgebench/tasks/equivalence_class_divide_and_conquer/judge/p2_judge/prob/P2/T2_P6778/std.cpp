#include<bits/stdc++.h>
using namespace std;
typedef unsigned ui;
typedef pair<int,ui>P;
char ibuf[1<<23],*ih=ibuf,obuf[1<<22],*oh=obuf;
inline void read(int&x){
	for(;!isdigit(*ih);++ih);
	for(x=0;isdigit(*ih);x=x*10+*ih++-48);
}
inline void out(ui x){
	if(!x){*oh++='0';return;}
	static int buf[30];int xb=0;
	for(;x;x/=10)buf[++xb]=x%10;
	for(;xb;)*oh++=buf[xb--]|48;
}
const int N=2e5+5,M=1600;
int n,m;
namespace Tree{
ui mem[N*4+M*9],*pp=mem;
inline ui*getm(int l){pp+=l;return pp-l;}
vector<P>e[N];
int x,y,z,i,dad[N],pos[N],bel[N],bcnt,faa[N],BL;ui deps[N],dep[N],fe[N];
bool bb[N];
struct tree1{
	ui*fa,*val,*dis,*w,x,y,l;
	inline void ini(int*a,int l,int xx,int yy){
		fa=getm(l+2);val=getm(l+2);w=getm(l+2);dis=getm(l+2);x=xx;y=yy;this->l=l;
		for(i=1;i<=l;++i)pos[a[i]]=i,bel[a[i]]=bcnt,w[i]=fe[a[i]];pos[x]=l+1;for(i=1;i<=l;++i)fa[i]=pos[dad[a[i]]];
		faa[y]=x;bb[x]=bb[y]=1;
		for(i=pos[y];i<=l;i=fa[i])dis[i]=w[i];for(i=l;i;--i)dis[i]+=dis[fa[i]];
	}
	inline void mdy(int u){
		static ui tmp[N];u=pos[u];
		memset(tmp+1,0,l+1<<2);for(i=u;i<=l;i=fa[i])tmp[i]=w[i];
		for(i=l;i;--i)val[i]+=tmp[i]+=tmp[fa[i]];
	}
}b1[M];
struct tree2{
	int fa[M],l;ui w[M],val2[M],val[M];
	inline void ini(){for(i=2;i<=n;++i)if(bb[i])fa[bel[i]]=bel[faa[i]],w[bel[i]]=dep[i]-dep[faa[i]];l=bcnt;}
	inline void mdy(int u){
		static ui tmp[N];
		memset(tmp+1,0,l<<2);
		if(bb[u])for(i=bel[u];i;i=fa[i])tmp[i]=w[i],++val2[i];else{
			for(i=fa[bel[u]];i;i=fa[i])tmp[i]=w[i],++val2[i];
			tmp[bel[u]]=b1[bel[u]].dis[pos[u]];
		}
		for(i=l;i;--i)val[i]+=tmp[i]+=tmp[fa[i]];
	}
}b2;
void dfs(int x,int fa){
	static int bo[N],st[N],w,vv[N],l[N],r[N],be[N],en[N],dcnt;int ct=0,ow=w;
	be[x]=++dcnt;for(P y:e[x])if(y.first!=fa)dad[y.first]=x,dep[y.first]=dep[x]+y.second,fe[y.first]=y.second,
		dfs(y.first,x),ct+=bo[y.first]>0,!bo[x]?bo[x]=bo[y.first]:0;
	if(ct>1 || w-ow+1>BL || x==1){
		int xb=0,j,k,nw;
		for(j=w;j>1 && be[st[j-1]]>=be[x];--j);nw=j;
		for(P y:e[x])if(y.first!=fa){for(l[++xb]=j,vv[xb]=y.first;j<=w && en[st[j]]<=en[y.first];++j);r[xb]=j-1;}
		for(j=1;j<=xb;j=k+1){
			int c=bo[vv[j]],cc=c>0;
			for(k=j;k<xb && r[k+1]-l[j]+1<=BL && cc+(bo[vv[k+1]]>0)<2;)
				++k,bo[vv[k]]>0?++cc,c=bo[vv[k]]:0;
			++bcnt;!c?c=st[l[j]]:0;b1[bcnt].ini(st+l[j]-1,r[k]-l[j]+1,x,c);
		}
		w=nw-1;
	}
	if(bb[x])bo[x]=x;en[x]=dcnt;st[++w]=x;
}
inline void main(){
	BL=500;
	for(i=1;i<n;++i)read(x),read(y),read(z),e[x].push_back({y,z}),e[y].push_back({x,z});
	dfs(1,0);b2.ini();for(i=1;i<=n;++i)deps[i]=deps[i-1]+dep[i];
}
inline void mdy(int x){b2.mdy(x);if(!bb[x])b1[bel[x]].mdy(x);}
inline ui ask(int x){
	int y=bel[x],z=pos[x];
	return bb[x]?b2.val[y]:b2.val[b2.fa[y]]+b2.val2[y]*b1[y].dis[z]+b1[y].val[z];
}
inline void clear(){
	for(i=1;i<=bcnt;++i)memset(b1[i].val+1,0,b1[i].l<<2);
	memset(b2.val2+1,0,b2.l<<2);memset(b2.val+1,0,b2.l<<2);
}
}
namespace MO{
int bl,i,l,r;
struct que{
	int l,r,i,k;
	inline bool operator<(const que&rhs)const{return l/bl==rhs.l/bl?l/bl&1?r>rhs.r:r<rhs.r:l<rhs.l;}
}qu[N];
ui ans[N],ansdt[N],s1[N],s2[N];
vector<que>q1[N],q2[N];
inline void work(ui*s,int be,int en,vector<que>*q,int v){
	Tree::clear();
	for(int i=be;i!=en;i+=v){
		s[i]=s[i-v]+Tree::ask(i);Tree::mdy(i);
		for(auto u:q[i])for(int j=u.l;j<=u.r;++j)ansdt[u.i]+=u.k*Tree::ask(j);
	}
}
inline void main(){
	for(i=1;i<=m;++i)read(l),read(r),qu[i]=(que){l,r,i},ans[i]=(Tree::deps[r]-Tree::deps[l-1])*(r-l);
	bl=sqrt(n);sort(qu+1,qu+m+1);l=1;r=0;
	for(i=1;i<=m;++i){
		if(l>qu[i].l)q2[r+1].push_back((que){qu[i].l,l-1,i,-1}),l=qu[i].l;
		if(r<qu[i].r)q1[l-1].push_back((que){r+1,qu[i].r,i,-1}),r=qu[i].r;
		if(l<qu[i].l)q2[r+1].push_back((que){l,qu[i].l-1,i,1}),l=qu[i].l;
		if(r>qu[i].r)q1[l-1].push_back((que){qu[i].r+1,r,i,1}),r=qu[i].r;
	}
	work(s1,1,n+1,q1,1);work(s2,n,0,q2,-1);
	l=1;r=0;
	for(i=1;i<=m;++i){
		if(l>qu[i].l)ansdt[i]+=s2[qu[i].l]-s2[l],l=qu[i].l;
		if(r<qu[i].r)ansdt[i]+=s1[qu[i].r]-s1[r],r=qu[i].r;
		if(l<qu[i].l)ansdt[i]-=s2[l]-s2[qu[i].l],l=qu[i].l;
		if(r>qu[i].r)ansdt[i]-=s1[r]-s1[qu[i].r],r=qu[i].r;
		ans[qu[i].i]-=2*(ansdt[i]+=ansdt[i-1]);
	}
	for(i=1;i<=m;++i)out(ans[i]),*oh++='\n';
}
}
int main(){
	fread(ibuf,1,1<<23,stdin);
	read(n),read(m);
	Tree::main();MO::main();
	fwrite(obuf,1,oh-obuf,stdout);
}
