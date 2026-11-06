// luogu-judger-enable-o2
#include <stdio.h>
#include <vector>
#include <math.h>
#include <string.h>
#include <algorithm>
#define MAXN 100010
#define belong( i ) ( ( i - 1 ) / cnt + 1 )
#define find( x ) ( num1[x] + num2[ ( x ) >> 8 ] )

using namespace std;

int n , m , a[ MAXN ] , b[ MAXN ] , cnt;
int num1[ MAXN + 256 ] , num2[ MAXN >> 8 ];
long long pre[ MAXN ] , suf[ MAXN ] , ans[ MAXN ];

struct ask
{
    int l , r , pos;
    ask( int l , int r , int pos ) : l( l ) , r( r ) , pos( pos ) {}
    ask() {}
} q[ MAXN ] , memory_pool[ MAXN << 1 ];

inline ask * get_memory( int x )
{
    cnt += x;
    return memory_pool + cnt - x;
}

inline bool cmp( const ask & a , const ask & b )
{
    return belong( a.l ) ^ belong( b.l ) ? belong( a.l ) < belong( b.l ) : belong( a.l ) & 1 ? a.r < b.r : a.r > b.r;
}

struct Vector
{
    ask * a , * b;
    inline void assign( int c )
    {
        b = a = get_memory( c );
    }
    inline void push_back( ask x )
    {
        * b++ = x;
    }
    inline int size()
    {
        return b - a;
    }
} linker1[ MAXN ] , linker2[ MAXN ];

struct io
{
    char ibuf[3 << 21] , * s , obuf[1 << 21] , * t;
    int a[24];
    io() : t( obuf )
    {
        fread( s = ibuf , 1 , 3 << 21 , stdin );
    }
    ~io()
    {
        fwrite( obuf , 1 , t - obuf , stdout );
    }
    inline int read()
    {
        register int u = 0;
        while( * s < 48 ) s++;
        while( * s > 32 )
            u = u * 10 + * s++ - 48;
        return u;
    }
    inline void pt( long long u )
    {
        static int * q = a;
        if( !u ) * t++ = 48;
        else
        {
            while( u ) * q++ = u % 10 + 48 , u /= 10;
            while( q != a )
                * t++ = * --q;
        }
    }
    inline void print( long long a )
    {
        pt( a ) , * t++ = '\n';
    }
} ip;

#define read ip.read
#define print ip.print

inline void query1( int x , int l , int r , int t )
{
    if( 1 <= x && x <= n )
        linker1[x].push_back( ask( l , r , t ) );
}

inline void query2( int x , int l , int r , int t )
{
    if( 1 <= x && x <= n )
        linker2[x].push_back( ask( l , r , t ) );
}

inline void modify_pre( register int x )
{
    x--;
    while( x >> 8 == x + 1 >> 8 ) num1[ x-- ]++;
    x-- , x >>= 8;
    while( x >= 0 ) num2[ x-- ]++;
}

inline void modify_suf( register int x )
{
    x++;
    while( x >> 8 == x - 1 >> 8 ) num1[ x++ ]++;
    x++ , x >>= 8;
    while( x <= n >> 8 ) num2[ x++ ]++;
}

int main()
{
    n = read() , m = read();
    for( register int i = 1 ; i <= n ; i++ )
        a[i] = b[i] = read();
    sort( b + 1 , b + n + 1 );
    cnt = unique( b + 1 , b + n + 1 ) - b;
    for( register int i = 1 ; i <= n ; i++ )
        a[i] = lower_bound( b + 1 , b + cnt + 1 , a[i] ) - b;
    cnt = n / sqrt( m * 2 / 3 );
    for( register int i = 1 ; i <= m ; i++ )
        q[i].l = read() , q[i].r = read() , q[i].pos = i;
    sort( q + 1 , q + m + 1 , cmp );
    cnt = 0;
    memset( b , 0 , sizeof( b ) );
    for( int i = 1 , l = 1 ; i <= m ; i++ )
        l = q[i].l , b[ l - 1 ]++;
    for( register int i = 1 ; i <= n ; i++ ) linker1[i].assign( b[i] );
    memset( b , 0 , sizeof( b ) );
    for( int i = 1 , r = 1 ; i <= m ; i++ )
        b[ r + 1 ]++ , r = q[i].r;
    for( register int i = 1 ; i <= n ; i++ ) linker2[i].assign( b[i] );
    for( int i = 1 , l = 1 , r = 1 ; i <= m ; i++ )
    {
        if( l < q[i].l ) query2( r + 1 , l , q[i].l - 1 , q[i].pos );
        else query2( r + 1 , q[i].l , l - 1 , -q[i].pos );
        l = q[i].l;
        if( r < q[i].r ) query1( l - 1 , r + 1 , q[i].r , -q[i].pos );
        else query1( l - 1 , q[i].r + 1 , r , q[i].pos );
        r = q[i].r;
    }
    for( int i = 1 ; i <= n ; i++ )
    {
        pre[i] = pre[i - 1] + find( a[i] );
        modify_pre( a[i] );
        for( ask * j = linker1[i].a ; j != linker1[i].b ; j++ )
            if( j -> pos > 0 )
                for( register int k = j -> l ; k <= j -> r ; k++ )
                    ans[ + j -> pos ] += find( a[k] );
            else
                for( register int k = j -> l ; k <= j -> r ; k++ )
                    ans[ - j -> pos ] -= find( a[k] );
    }
    memset( num1 , 0 , sizeof( num1 ) );
    memset( num2 , 0 , sizeof( num2 ) );
    for( int i = n ; i ; i-- )
    {
        suf[i] = suf[i + 1] + find( a[i] );
        modify_suf( a[i] );
        for( ask * j = linker2[i].a ; j != linker2[i].b ; j++ )
            if( j -> pos > 0 )
                for( register int k = j -> l ; k <= j -> r ; k++ )
                    ans[ + j -> pos ] += find( a[k] );
            else
                for( register int k = j -> l ; k <= j -> r ; k++ )
                    ans[ - j -> pos ] -= find( a[k] );
    }
    for( int i = 1 , l = 1 , r = 1 ; i <= m ; i++ )
    {
        ans[ q[i].pos ] += suf[ q[i].l ] - suf[l];
        ans[ q[i].pos ] += pre[ q[i].r ] - pre[r];
        l = q[i].l , r = q[i].r;
    }
    for( register int i = 1 ; i <= m ; i++ )
        ans[ q[i].pos ] += ans[ q[i - 1].pos ];
    for( register int i = 1 ; i <= m ; i++ )
        print( ans[i] );
    return 0;
}
