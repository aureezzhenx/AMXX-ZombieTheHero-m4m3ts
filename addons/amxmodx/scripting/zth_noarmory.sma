#include <amxmodx> 
#include <fakemeta> 

new g_FwdKeyValue;

public plugin_precache() 
{ 
	g_FwdKeyValue = register_forward( FM_KeyValue, "Forward_KeyValue" );
} 

public Forward_KeyValue( const EntIndex, const KvdHandle ) 
{ 
	if ( pev_valid( EntIndex ) ) 
	{ 
		new szClassName[ 16 ];
		get_kvd( KvdHandle, KV_ClassName, szClassName, charsmax( szClassName ) );
            
		if( equal( szClassName, "armoury_entity" ) )
		{ 
			engfunc( EngFunc_RemoveEntity, EntIndex );
			return FMRES_SUPERCEDE;
		}
        } 
        return FMRES_IGNORED;
} 
    
public plugin_init() 
{ 
	register_plugin( "No Armoury", "1.0.0", "Arkshine" );
	unregister_forward( FM_KeyValue, g_FwdKeyValue );
}
