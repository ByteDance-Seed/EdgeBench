#include<bits/stdc++.h>
using namespace std;
namespace fio{
    const int SZ=(1<<22);
    char ibuf[SZ],obuf[SZ];
    int ips=SZ,ops,stk[20],top;
    char gc(){
        ips==SZ?fread(ibuf,1,SZ,stdin),ips=0:0;
        return ibuf[ips++];
    }
    void flush(){ fwrite(obuf,1,ops,stdout),ops=0; }
    void pc(char c){
        if(ops==SZ) flush();
        obuf[ops++]=c;
    }
    template<typename tp> void rd(tp &x){
        char c=gc();
        bool f=0;
        for(;(c<'0'||c>'9')&&c!='-';c=gc()) ;
        if(c=='-') f=1,c=gc();
        for(x=0;c>='0'&&c<='9';c=gc()) x=x*10+c-'0';
        if(f) x=-x;
    }
    template<typename _tp> void wrt(_tp x){
        if(x<0){
            pc('-');
            stk[++top]=-(x%10);
            x=-(x/10);
            if(!x){
                while(top) pc(stk[top--]+'0');
                return ;
            }
        }
        for(x?0:stk[++top]=0;x;x/=10) stk[++top]=x%10;
        while(top) pc(stk[top--]+'0');
    }
    struct A{
        template<typename tp> A& operator >> (tp &x){
            rd(x);
            return *this;
        }
    }fin;
    struct B{
        B& operator << (char c){
            pc(c);
            return *this;
        }
        B& operator << (const char *c){
            for(;*c;c++) pc(*c);
            return *this;
        }
        template<typename _tp> B& operator << (_tp x){
            wrt(x);
            return *this;
        }
    }fout;
}
using fio::fin;
using fio::fout;
#define db(x...) fprintf(stderr,x)
const int N=1e6+5,B=1000;
int n,m,bel[N];
vector<int> e[N];
int stk[N],ed[N],sz[N],top,bg[N];
int dep[N],p[N];
void add(int u,int v,int l,int r){
    // db("add %d to %d\n",u,v);
    // for(int i=l;i<=r;++i) db("%d%c",stk[i]," \n"[i==r]);
    if(!u) return ;
    for(int t=u;t^v;t=p[t]) bel[t]=u;
}
void dfs(int u){
    bg[u]=top;
    int num=0;
    for(auto v:e[u]){
        stk[++top]=v,sz[v]=1,dep[v]=dep[u]+1;
        dfs(v),sz[u]+=sz[v];
        if(ed[v]) ed[u]=ed[v],++num;
    }
    if(u==1||sz[u]>=B||num>1){
        // db("slv %d----\n",u);
        int l=e[u].size(),lst=0,s=0,tl=bg[u]+1;
        for(int i=0;i<l;++i){
            int v=e[u][i];
            if((lst&&ed[u])||s>=B){
                sz[u]-=s;
                add(lst,u,tl,bg[e[u][i-1]]);
                lst=0,s=0,tl=bg[e[u][i-1]]+1;
            }
            s+=sz[v],lst|=ed[v];
        }
        // db("s %d\n",s);
        if(s) add(lst,u,tl,top),sz[u]-=s;
        ed[u]=u,top=bg[u];
    }
}
struct opt{
    int op,x,y;
}pool[N*5+5];
int cnt;
struct qrd{
    int u,d,id;
};
vector<qrd> qr[N];
bool cmp(qrd &a,qrd &b){ return dep[a.u]+a.d<dep[b.u]+b.d; }
void slv(int u){
    sort(qr[u].begin(),qr[u].end(),cmp);
    int ct=0;
    for(auto p:qr[u]){
        if(dep[p.u]+p.d<dep[u]){
            pool[++cnt]={1,p.u,p.d};
            pool[++cnt]={3,p.id,0};
            pool[++cnt]={2,0,0};
        }else{
            pool[++cnt]={1,u,dep[p.u]+p.d-dep[u]};
            pool[++cnt]={1,p.u,p.d};
            pool[++cnt]={3,p.id,0};
            pool[++cnt]={2,0,0};
            ++ct;
        }
    }
    while(ct--) pool[++cnt]={2,0,0};
}
int main(){
    fin>>n>>m;
    for(int i=2;i<=n;++i) fin>>p[i],e[p[i]].push_back(i);
    dfs(1);
    bel[1]=1;
    int u,d;
    for(int i=1;i<=m;++i){
        fin>>u>>d;
        if(!bel[u]) pool[++cnt]={1,u,d},pool[++cnt]={3,i,0},pool[++cnt]={2,0,0};
        else qr[bel[u]].push_back({u,d,i});
    }
    for(int i=1;i<=n;++i)
        if(bel[i]==i) slv(i);
    fout<<cnt<<"\n";
    for(int i=1;i<=cnt;++i)
        if(pool[i].op==1) fout<<"1 "<<pool[i].x<<" "<<pool[i].y<<"\n";
        else if(pool[i].op==2) fout<<"2\n";
        else fout<<"3 "<<pool[i].x<<"\n";
    fio::flush();
    return 0;
}
