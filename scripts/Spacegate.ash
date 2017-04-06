since r17948;
/*
Spacegate
Farms spacegate research. Probably will unlock other things when other things are spaded.
This file is in the public domain.
*/

//Settings that probably should have a better interface:
//Alien gemstones can be sold in the mall. Set this to true if you don't care about that. Most people probably don't, but...
boolean __setting_turn_in_alien_gemstones = false;

//Turns in rocks at the end of the run. Turn this off if you want to be the top collector of space rocks.
boolean __setting_automatically_turn_in_research = true;

//Always use this planet.
string __setting_planet_override = "";



string __spacegate_version = "1.0.6";










//Utility, stolen from guide:
//to_int will print a warning, but not halt, if you give it a non-int value.
//This function prevents the warning message.
//err is set if value is not an integer.
int to_int_silent(string value)
{
    //to_int() supports floating-point values. is_integer() will return false.
    //So manually strip out everything past the dot.
    //We probably should just ask for to_int() to be silent in the first place.
    int dot_position = value.index_of(".");
    if (dot_position != -1 && dot_position > 0) //two separate concepts - is it valid, and is it past the first position. I like testing against both, for safety against future changes.
    {
        value = value.substring(0, dot_position);
    }
    
	if (is_integer(value))
        return to_int(value);
	return 0;
}

//Silly conversions in case we chose the wrong function, removing the need for a int -> string -> int hit.
int to_int_silent(int value)
{
    return value;
}

int to_int_silent(float value)
{
    return value;
}
string [int] listMakeBlankString()
{
	string [int] result;
	return result;
}
//split_string returns an immutable array, which will error on certain edits
//Use this function - it converts to an editable map.
string [int] split_string_mutable(string source, string delimiter)
{
	string [int] result;
	string [int] immutable_array = split_string(source, delimiter);
	foreach key in immutable_array
		result[key] = immutable_array[key];
	return result;
}
//This returns [] for empty strings. This isn't standard for split(), but is more useful for passing around lists. Hacky, I suppose.
string [int] split_string_alternate(string source, string delimiter)
{
    if (source.length() == 0)
        return listMakeBlankString();
    return split_string_mutable(source, delimiter);
}
//End utility.





//State:
Record Spacestate
{
	boolean dialed;
	string planet_coordinates;
	string planet_name;
	
	int energy_remaining;
	string plant_life;
	string animal_life;
	string intelligent_life;
	boolean [string] environmental_hazards;
	boolean [string] alerts;
	
	//Consequences:
	boolean [item] equipment_needed;
	int probable_energy_remaining;
};

void calculateEquipmentNeeded(Spacestate state)
{
	/*
	A voice from the terminal says "Extremely high gravity detected. Exo-servo leg braces required for adequate mobility."
	A voice from the terminal says "High radiation levels detected. Rad cloak required for minimal survivable conditions."
	A voice from the terminal says "Intense winds detected. High-friction boots required for safe traversal."
	*/
	if (state.environmental_hazards["toxic atmosphere"]) //GUESS
		state.equipment_needed[$item[filter helmet]] = true;
	if (state.environmental_hazards["high gravity"])
		state.equipment_needed[$item[exo-servo leg braces]] = true;
	if (state.environmental_hazards["irradiated"])
		state.equipment_needed[$item[rad cloak]] = true;
	if (state.environmental_hazards["magnetic storms"]) //GUESS
		state.equipment_needed[$item[gate transceiver]] = true;
	if (state.environmental_hazards["high winds"])
		state.equipment_needed[$item[high-friction boots]] = true;
	//Now pick a sample kit:
	//geological sample kit, botanical sample kit, or zoological sample kit
	state.equipment_needed[$item[geological sample kit]] = true; //For now?
}

Spacestate determineState()
{
	Spacestate state;
	buffer page_text = visit_url("place.php?whichplace=spacegate&action=sg_Terminal");
	state.dialed = true;
	if (page_text.contains_text("It looks like you can either set seven dials individually, type in a seven letter coordinate set, or press a big red button to open the gate up to a random planet."))
	{
		state.dialed = false;
		return state;
	}
	
	string [int][int] first_level_match = page_text.group_string("<center><table><tr><td>Current planet: Planet Name: (.*?)<br>Coordinates: (.*?)<br><p>Environmental Hazards:<Br>(.*?)<br>Plant Life: (.*?)<br>Animal Life: (.*?)<br>Intelligent Life: (.*?)<br><p>Spacegate Energy remaining: <b><font size=.2>([0-9]*) </font></b>Adventure");
	
	state.planet_name = first_level_match[0][1];
	state.planet_coordinates = first_level_match[0][2];
	state.plant_life = first_level_match[0][4];
	state.animal_life = first_level_match[0][5];
	state.energy_remaining = first_level_match[0][7].to_int_silent();
	state.probable_energy_remaining = state.energy_remaining;
	
	string environmental_hazards_string = first_level_match[0][3].replace_string("&nbsp;", "");
	string [int] el_hazard = environmental_hazards_string.split_string_alternate("<br>");
	foreach key, hazard in el_hazard
	{
		state.environmental_hazards[hazard] = true;
	}
	
	string [int] second_level_match = first_level_match[0][6].split_string_alternate("<br>");
	//print_html("second_level_match = \"" + second_level_match.to_json() + "\"");
	state.intelligent_life = second_level_match[0];
	foreach key, entry in second_level_match
	{
		if (key == 0) continue;
		state.alerts[entry] = true;
	}
	
	calculateEquipmentNeeded(state);
	
	//print_html("first_level_match = " + first_level_match.to_json().entity_encode());
	//print_html("state = " + state.to_json().entity_encode());
	return state;
}


string pickPlanet()
{
	if (__setting_planet_override != "")
		return __setting_planet_override;
	//FIXME properly do this
	//Ideally we want to unlock everything, on planets that don't have combats.
	//int space_baby_language_fluency = get_property("spaceBabyLanguageFluency").to_int_silent();
	int space_pirate_language_fluency = get_property("spacePirateLanguageFluency").to_int_silent(); //property name guess
	if (space_pirate_language_fluency >= 100)
		return "ZYXWVUT";
	else
		return "ZZZZZZZ";
	//Consider VANANAS:
	//Space rocks + Here There Be No Spants, gives ~355 + gemstones.
	//Here There Be No Spants is worth 25 pages. Rock formations are worth.. hmm... 15-18 + gemstone_rate * 100? What's the gemstone rate? Guessing 5% for now, from preliminary data. Soo... 20-23? That's less than 25.
	//Need to spade whether rocks from lower-difficulty planets give less on average, before we consider switching. Or just find a Z planet with rocks + no combats + spants.
}

void acquireAndEquipNeededEquipment(Spacestate state)
{
	int [item] choice_ids_for_equipment;
	choice_ids_for_equipment[$item[filter helmet]] = 1;
	choice_ids_for_equipment[$item[exo-servo leg braces]] = 2;
	choice_ids_for_equipment[$item[rad cloak]] = 3;
	choice_ids_for_equipment[$item[gate transceiver]] = 4;
	choice_ids_for_equipment[$item[high-friction boots]] = 5;
	choice_ids_for_equipment[$item[geological sample kit]] = 6;
	choice_ids_for_equipment[$item[botanical sample kit]] = 7;
	choice_ids_for_equipment[$item[zoological sample kit]] = 8;
	
	foreach it in state.equipment_needed
	{
		if (it.available_amount() == 0 && choice_ids_for_equipment contains it)
		{
			visit_url("place.php?whichplace=spacegate&action=sg_requisition");
			visit_url("choice.php?whichchoice=1233&option=" + choice_ids_for_equipment[it]);
		}
		if (it.available_amount() > 0 && it.equipped_amount() == 0)
		{
			equip(it);
		}
	}
}

void main()
{
	print("Spacegate version " + __spacegate_version + ".");
	if (!get_property("spacegateAlways").to_boolean() || in_bad_moon())
	{
		if (!visit_url("place.php?whichplace=spacegate").contains_text("Secret Underground Spacegate Facility"))
		{
			print("You don't appear to have a spacegate.");
			return;
		}
	}
	if (inebriety_limit() - my_inebriety() < 0)
	{
		print("You are overdrunk.");
		return;
	}
	
	int alien_gemstones_before = to_item("alien gemstone").item_amount();
	
	item [slot] saved_outfit;
	foreach s in $slots[hat,weapon,off-hand,back,shirt,pants,acc1,acc2,acc3,familiar]
		saved_outfit[s] = s.equipped_item();
		
	//Method used:
	//Pick a Z-planet (does this affect rock count?) with no combats, and equip the right kit.
	
	//place.php?whichplace=spacegate&action=sg_Terminal
	//Cool space rocks - 1255, 2 with geology kit, 1 otherwise
	//Space cave - 1236, 2 with geology kit, 1 otherwise
	//Wide open spaces - 1256, 2 with geology kit, 1 otherwise
	//106 alien rock samples from ZYXWVUT, but no alien gemstones yet.
	//ZZZZZZZ is similar, but with one pirate NC. Which means one less rock, but one extra pirate language.
	
	//boolean [item] items_to_track = $items[alien rock sample,alien gemstone];
	int breakout = 100;
	boolean did_adventure = false;
	Spacestate state = determineState();
	while (breakout > 0 && my_adventures() > 0)
	{
		//Only reload if we think we're done:
		if (state.probable_energy_remaining <= 0 && state.energy_remaining != 0)
			state = determineState();
		if (!state.dialed)
		{
			//Pick a planet:
			string desired_planet = pickPlanet();
			print("Dialing planet " + desired_planet + "...");
			visit_url("place.php?whichplace=spacegate&action=sg_Terminal");
			visit_url("choice.php?whichchoice=1235&option=2&word=" + desired_planet);
			state = determineState();
			continue;
		}
		if (state.energy_remaining <= 0)
		{
			print("Out of energy for today.");
			break;
		}
		acquireAndEquipNeededEquipment(state);
		
		//Only restore one HP if it's just rocks:
		int hp_desired = 1;
		if (state.plant_life != "none detected" || state.animal_life != "none detected" || state.intelligent_life != "none detected")
			hp_desired = my_maxhp();
		//So... if all of those are none, what happens with spant/murderbots? Do you encounter fights? I don't think so?
		if (my_hp() < hp_desired)
			restore_hp(hp_desired);
		
		//Set all the choice adventures:
		int [int] choice_adventure_settings;
		choice_adventure_settings[1244] = 1; //Here There Be No Spants
		choice_adventure_settings[1246] = 1; //Land Ho, pirate language scrolls
		if ($item[geological sample kit].equipped_amount() > 0)
		{
			choice_adventure_settings[1255] = 2;
			choice_adventure_settings[1236] = 2;
			choice_adventure_settings[1256] = 2;
		}
		else
		{
			choice_adventure_settings[1255] = 1;
			choice_adventure_settings[1236] = 1;
			choice_adventure_settings[1256] = 1;
		}
		foreach choice_id, value in choice_adventure_settings
		{
			set_property("choiceAdventure" + choice_id, value);
		}
		did_adventure = true;
		boolean success = adv1($location[through the spacegate], -1, "");
		if (!success)
		{
			print("Unknown error, stopping.");
			break;
		}
		state.probable_energy_remaining -= 1;
	}
	foreach s, it in saved_outfit
	{
		if (s.equipped_item() != it)
			equip(s, it);
	}
	
	if (my_adventures() == 0)
	{
		state = determineState();
		if (state.energy_remaining != 0)
			print("Ran out of adventures.");
	}
		
	if (__setting_automatically_turn_in_research && did_adventure)
	{
		string closet_amount = "*";
		boolean ignore_closet = false;
		if (to_item("alien gemstone") != $item[none])
		{
			int amount = to_item("alien gemstone").item_amount();
			if (amount == 0)
				ignore_closet = true;
			else
				closet_amount = amount.to_string();
		}
		if (!__setting_turn_in_alien_gemstones && !ignore_closet)
			cli_execute("closet put " + closet_amount + " alien gemstone");
		int research_before = $item[Spacegate Research].available_amount();
		visit_url("place.php?whichplace=spacegate&action=sg_tech");
		int research_after = $item[Spacegate Research].available_amount();
		if (!__setting_turn_in_alien_gemstones && !ignore_closet)
			cli_execute("closet take " + closet_amount + " alien gemstone");
	
		int research_gained = research_after - research_before;
		
		int alien_gemstones_after = to_item("alien gemstone").item_amount();
		int alien_gemstones_gained = alien_gemstones_after - alien_gemstones_before;
		
		if (research_gained > 0)
		{
			string line = "Earned " + research_gained + " research";
			if (alien_gemstones_gained > 0)
			{
				line += " and " + alien_gemstones_gained + " alien gemstone";
				if (alien_gemstones_gained > 1)
					line += "s";
			}
			line += ".";
			print(line);
		}
	}
}