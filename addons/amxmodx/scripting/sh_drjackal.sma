// Dr.Jackal! - Knife Master

/* CVARS - copy and paste to shconfig.cfg

//Dr jackal
drjackal_level 0
drjackal_speed 10000		//the speed he can run
drjackal_alpha 50		//Alpha level when invisible. 0 = invisible, 255 = full visibility.
drjackal_delay 1		//Time a player must be still to become invisible
drjackal_checkmove 0 	//Should movement be checked, or only shooting? 0 = only check shooting
drjackal_knifemult 10           //Damage multiplied when using knife
drjackal_armor 250              //Starting armor he starts with
drjackal_health 250             //Starting health he starts with
drjackal_gravity 0.35           //The gravity he is in
drjackal_healpoints 10          //The amount of hp he heals per sec
*/

#include <amxmod>
#include <superheromod>
#include <Vexd_Utilities>
#include <engine>

// GLOBAL VARIABLES
new gHeroName[]="Dr jackal"
new bool:gHasDrjackalPowers[SH_MAXSLOTS+1]
new gIsInvisible[SH_MAXSLOTS+1]
new gStillTime[SH_MAXSLOTS+1]
new gPlayerMaxHealth[SH_MAXSLOTS+1]
new gHealPoints
new Float:jumpVeloc[33][3]
new bool:caughtJump[33]
new bool:doJump[33]
new newButton[33]
new numJumps[33]
new g_bwEnt[33]
new wallteam
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Dr jackal","1.0","D4rkSh4d0w")

	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	register_cvar("drjackal_level", "0" )
	register_cvar("drjackal_speed", "10000" )
	register_cvar("drjackal_alpha", "50" )
	register_cvar("drjackal_delay", "5" )
	register_cvar("drjackal_checkmove", "1")
	register_cvar("drjackal_knifemult", "10")
	register_cvar("drjackal_gravity", "0.35" )
	register_cvar("drjackal_armor", "250")
	register_cvar("drjackal_health", "250")
	register_cvar("drjackal_healpoints", "10")

        // IGNORE THIS
	register_cvar("walljump_str","500.0")
	register_cvar("walljump_num","99999")
	register_cvar("walljump_team", "0")
                                      

	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	shCreateHero(gHeroName, "The Master of Knives", "You will be too fast too be seen and you can         instant kill with a knife ",
	false, "drjackal_level" )

        register_touch("player", "worldspawn", "Touch_World")
	register_touch("player", "func_wall", "Touch_World")
	register_touch("player", "func_breakable", "Touch_World")

        // REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
	// INIT
	register_srvcmd("drjackal_init", "drjackal_init")
	shRegHeroInit(gHeroName, "drjackal_init")

	// CHECK SOME BUTTONS
	set_task(0.1,"checkButtons",0,"",0,"b")
       
         // Knife Model
	register_event("ResetHUD", "newSpawn","b")
	register_event("CurWeapon", "weaponChange","be","1=1")
         
	 // EXTRA KNIFE DAMAGE
	register_event("Damage", "drjackal_damage", "b", "2!0")
	
	// HEAL LOOP
	set_task(1.0, "drjackal_loop", 0, "", 0, "b")
	
	// Let Server know about Tutorials Variable
	// It is possible that another hero has more hps, less gravity, or more armor
	// so rather than just setting these - let the superhero module decide each round
	shSetMaxHealth(gHeroName, "drjackal_health" )
	shSetMinGravity(gHeroName, "drjackal_gravity" )
	shSetMaxArmor(gHeroName, "drjackal_armor" )
	shSetMaxSpeed(gHeroName, "drjackal_speed", "[0]" )
	
	// Let Server know about Dr Jackal's Varibles
	register_srvcmd("drjackal_maxhealth", "drjackal_maxhealth")
	shRegMaxHealth(gHeroName, "drjackal_maxhealth")
	gHealPoints = get_cvar_num("drjackal_healpoints")
}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
	precache_model("models/shmod/wolv_knife.mdl")
}
//----------------------------------------------------------------------------------------------
public drjackal_init()
{	
	// First Argument is an id
	new temp[6]
	read_argv(1,temp,5)
	new id=str_to_num(temp)

	// 2nd Argument is 0 or 1 depending on whether the id has Dr Jackal
	read_argv(2,temp,5)
	new hasPowers = str_to_num(temp)	
	gHasDrjackalPowers[id] = (hasPowers != 0)

	gPlayerMaxHealth[id] = 100
	
	switchmodel(id)
	
	//Give Powers to the Dr Jackal
	if ( !gHasDrjackalPowers[id] ) remInvisibility(id)
}
//----------------------------------------------------------------------------------------------
public newRound(id)
{
  gPlayerUltimateUsed[id]=false
  return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
public client_connect(id)
{
	if(g_bwEnt[id] > 0)
		remove_entity(g_bwEnt[id])
	g_bwEnt[id] = 0
}
//----------------------------------------------------------------------------------------------
public client_disconnect(id) {
	if(g_bwEnt[id] > 0)
		remove_entity(g_bwEnt[id])
	g_bwEnt[id] = 0

	gHasDrjackalPowers[id] = false
}
//----------------------------------------------------------------------------------------------
public client_PreThink(id)
{
	wallteam = get_cvar_num("walljump_team")
	new team = get_user_team(id)
	if(gHasDrjackalPowers[id] && (!wallteam || wallteam == team)) 
	{
		newButton[id] = get_user_button(id)
		new oldButton = get_user_oldbutton(id)
		new flags = get_entity_flags(id)
		
		//reset if we are on ground
		if(caughtJump[id] && (flags & FL_ONGROUND)) 
		{
			numJumps[id] = 0
			caughtJump[id] = false
		}
		
		//begin when we jump
		if((newButton[id] & IN_JUMP) && (flags & FL_ONGROUND) && !caughtJump[id] && !(oldButton & IN_JUMP) && !numJumps[id]) 
		{
			caughtJump[id] = true
			entity_get_vector(id,EV_VEC_velocity,jumpVeloc[id])
			jumpVeloc[id][2] = get_cvar_float("walljump_str")
		}
	}
}
//----------------------------------------------------------------------------------------------
public client_PostThink(id) 
{
	if(gHasDrjackalPowers[id] && is_user_alive(id)) 
	{
		//do velocity if we walljumped
		if(doJump[id]) 
		{
			entity_set_vector(id,EV_VEC_velocity,jumpVeloc[id])
			
			doJump[id] = false
			
			if(numJumps[id] >= get_cvar_num("walljump_num")) //reset if we ran out of jumps
			{
				numJumps[id] = 0
				caughtJump[id] = false
			}
		}
	}
}
//----------------------------------------------------------------------------------------------
public Touch_World(id, world) 
{
	if(gHasDrjackalPowers[id] && is_user_alive(id)) 
	{
		//if we touch wall and have jump pressed, setup for jump
		if(caughtJump[id] && (newButton[id] & IN_JUMP) && !(get_entity_flags(id) & FL_ONGROUND)) 
		{
			
			//reverse velocity
			for(new x=0;x<2;x++)
				jumpVeloc[id][x] *= -1.0
				
			numJumps[id]++
			doJump[id] = true
		}	
	}
}
//----------------------------------------------------------------------------------------------
public drjackal_loop()
{
	if ( !shModActive() ) return
	for ( new id = 1; id <= SH_MAXSLOTS; id++ ) {
		if ( gHasDrjackalPowers[id] && is_user_alive(id) ) {
			// Let the server add the hps back since the # of max hps is controlled by it
			// I.E. Superman has more than 100 hps etc.
			shAddHPs(id, gHealPoints, gPlayerMaxHealth[id])
		}
	}
}
//----------------------------------------------------------------------------------------------
public drjackal_maxhealth()
{
	new id[6]
	new health[9]

	read_argv(1,id,5)
	read_argv(2,health,8)

	gPlayerMaxHealth[str_to_num(id)] = str_to_num(health)
}

//----------------------------------------------------------------------------------------------
public setInvisibility(id, alpha)
{

	if (alpha < 125) {
		set_user_rendering(id,kRenderFxGlowShell,8,8,8,kRenderTransAlpha,alpha)
	}
	else {
		set_user_rendering(id,kRenderFxNone,0,0,0,kRenderTransAlpha,alpha)
	}
}
//----------------------------------------------------------------------------------------------
public checkButtons()
{
	if ( !hasRoundStarted() || !shModActive()) return

	new bool:setVisible
	new butnprs

	for(new id = 1; id <= SH_MAXSLOTS; id++) {
		if (!is_user_alive(id) || !gHasDrjackalPowers[id]) continue

		setVisible = false		

		//Always check these
		if (butnprs&IN_ATTACK || butnprs&IN_ATTACK2 || butnprs&IN_RELOAD || butnprs&IN_USE) 
		setVisible = true

		//Only check these if drjackal_checkmove is off
		if ( get_cvar_num("drjackal_checkmove") ) {
			if (butnprs&IN_JUMP) setVisible = true
			if (butnprs&IN_FORWARD || butnprs&IN_BACK || butnprs&IN_LEFT || butnprs&IN_RIGHT) setVisible = true
			if (butnprs&IN_MOVELEFT || butnprs&IN_MOVERIGHT) setVisible = true
		}

		if (setVisible) remInvisibility(id)
		else {
			new sysTime = get_systime()
			new delay = get_cvar_num("drjackal_delay")

			if ( gStillTime[id] < 0 ) {
				gStillTime[id] = sysTime
			}
			if ( sysTime - delay >= gStillTime[id] ) {
				if (gIsInvisible[id] != 100) client_print(id,print_center,
				"[SH]Your movements are swift: 100%s cloaked", "%")	
				gIsInvisible[id] = 100
				setInvisibility(id, get_cvar_num("drjackal_alpha"))
			}
			else if ( sysTime > gStillTime[id] ) {
				new alpha = get_cvar_num("drjackal_alpha")
				new Float:prcnt =  float(sysTime - gStillTime[id]) / float(delay)
				new rPercent = floatround(prcnt * 100)
				alpha = floatround(255 - ((255 - alpha) * prcnt) )
				client_print(id,print_center,"[SH])You move to fast to be seen[%d%s Invincible]",
				rPercent, "%")
				
				gIsInvisible[id] = rPercent
				setInvisibility(id, alpha)
			}
		}
	}
}
//----------------------------------------------------------------------------------------------
public remInvisibility(id)
{
	gStillTime[id] = -1

	if (gIsInvisible[id] > 0) {
		shUnglow(id)
		client_print(id,print_center,"[SH]Too Slow: You are no longer invincible")
	}

	gIsInvisible[id] = 0
}
//----------------------------------------------------------------------------------------------
public drjackal_damage(id)
{
	if ( !shModActive() || !is_user_alive(id) ) return

	new damage = read_data(2)
	new weapon, bodypart, attacker = get_user_attacker(id, weapon, bodypart)
	new headshot = bodypart == 1 ? 1 : 0

	if ( attacker <= 0 || attacker > SH_MAXSLOTS ) return

	if ( gHasDrjackalPowers[attacker] && weapon == CSW_KNIFE && is_user_alive(id) ) {
		// do extra damage
		new extraDamage = floatround(damage * get_cvar_float("drjackal_knifemult") - damage)
		if (extraDamage > 0) shExtraDamage(id, attacker, extraDamage, "knife", headshot)
	}
}
//----------------------------------------------------------------------------------------------
public newSpawn(id)
{
	if ( gHasDrjackalPowers[id] && is_user_alive(id) && shModActive() ) {
		new clip, ammo, wpnid = get_user_weapon(id,clip,ammo)
		if (wpnid != CSW_KNIFE && wpnid > 0) {
			new wpn[32]
			get_weaponname(wpnid,wpn,31)
			engclient_cmd(id,wpn)
		}
	}
}
//----------------------------------------------------------------------------------------------
public switchmodel(id)
{
	if ( !is_user_alive(id) || !gHasDrjackalPowers[id] ) return
	new clip, ammo, wpnid = get_user_weapon(id,clip,ammo)
	if (wpnid == CSW_KNIFE) {
		// Weapon Model change thanks to [CCC]Taz-Devil
		Entvars_Set_String(id, EV_SZ_viewmodel, "models/shmod/wolv_knife.mdl")
	}
}
//----------------------------------------------------------------------------------------------
public weaponChange(id)
{
	if ( !gHasDrjackalPowers[id] || !shModActive() ) return

	//new clip, ammo, wpnid = get_user_weapon(id,clip,ammo)
	new wpnid = read_data(2)

	if ( wpnid == CSW_KNIFE ) switchmodel(id)
}
//----------------------------------------------------------------------------------------------