/**********************Light************************/

//this item is intended to give the effect of entering the mine, so that light gradually fades
/obj/effect/light_emitter
	name = "Light-emtter"
	anchored = 1
	unacidable = 1
	luminosity = 8

/**********************Miner Lockers**************************/

/obj/structure/closet/secure_closet/miner
	name = "miner's equipment"
	icon_state = "miningsec1"
	icon_closed = "miningsec"
	icon_locked = "miningsec1"
	icon_opened = "miningsecopen"
	icon_broken = "miningsecbroken"
	icon_off = "miningsecoff"
	req_access = list(access_mining)

/obj/structure/closet/secure_closet/miner/New()
	..()
	sleep(2)
	if(prob(50))
		new /obj/item/weapon/storage/backpack/industrial(src)
	else
		new /obj/item/weapon/storage/backpack/satchel_eng(src)
	new /obj/item/device/radio/headset/headset_cargo(src)
	new /obj/item/clothing/under/rank/miner(src)
	new /obj/item/clothing/gloves/black(src)
	new /obj/item/clothing/shoes/black(src)
	new /obj/item/device/geoscanner(src)
	new /obj/item/weapon/storage/bag/ore(src)
	new /obj/item/device/flashlight/lantern(src)
	new /obj/item/weapon/shovel(src)
//	new /obj/item/weapon/pickaxe(src)
	new /obj/item/clothing/glasses/hud/mining(src)


/**********************Shuttle Computer**************************/

var/mining_shuttle_tickstomove = 10
var/mining_shuttle_moving = 0
var/mining_shuttle_location = 0 // 0 = station 13, 1 = mining station

proc/move_mining_shuttle()
	if(mining_shuttle_moving)	return
	mining_shuttle_moving = 1
	spawn(mining_shuttle_tickstomove*10)
		var/area/fromArea
		var/area/toArea
		if (mining_shuttle_location == 1)
			fromArea = locate(/area/shuttle/mining/outpost)
			toArea = locate(/area/shuttle/mining/station)

		else
			fromArea = locate(/area/shuttle/mining/station)
			toArea = locate(/area/shuttle/mining/outpost)

		var/list/dstturfs = list()
		var/throwy = world.maxy

		for(var/turf/T in toArea)
			dstturfs += T
			if(T.y < throwy)
				throwy = T.y

		// hey you, get out of the way!
		for(var/turf/T in dstturfs)
			// find the turf to move things to
			var/turf/D = locate(T.x, throwy - 1, 1)
			//var/turf/E = get_step(D, SOUTH)
			for(var/atom/movable/AM as mob|obj in T)
				AM.Move(D)
				// NOTE: Commenting this out to avoid recreating mass driver glitch
				/*
				spawn(0)
					AM.throw_at(E, 1, 1)
					return
				*/

			if(istype(T, /turf/simulated))
				del(T)

		for(var/mob/living/carbon/bug in toArea) // If someone somehow is still in the shuttle's docking area...
			bug.gib()

		for(var/mob/living/simple_animal/pest in toArea) // And for the other kind of bug...
			pest.gib()

		fromArea.move_contents_to(toArea)
		if (mining_shuttle_location)
			mining_shuttle_location = 0
		else
			mining_shuttle_location = 1

		for(var/mob/M in toArea)
			if(M.client)
				spawn(0)
					if(M.buckled)
						shake_camera(M, 3, 1) // buckled, not a lot of shaking
					else
						shake_camera(M, 10, 1) // unbuckled, HOLY SHIT SHAKE THE ROOM
			if(istype(M, /mob/living/carbon))
				if(!M.buckled)
					M.Weaken(3)

		mining_shuttle_moving = 0
	return

/obj/machinery/computer/mining_shuttle
	name = "mining shuttle console"
	icon = 'icons/obj/computer.dmi'
	icon_state = "shuttle"
	req_access = list(access_mining)
	circuit = "/obj/item/weapon/circuitboard/mining_shuttle"
	var/hacked = 0
	var/location = 0 //0 = station, 1 = mining base

/obj/machinery/computer/mining_shuttle/attack_hand(user as mob)
	if(..(user))
		return
	src.add_fingerprint(usr)
	var/dat

	dat = "<center>Mining Shuttle Control<hr>"

	if(mining_shuttle_moving)
		dat += "Location: <font color='red'>Moving</font> <br>"
	else
		dat += "Location: [mining_shuttle_location ? "Outpost" : "Station"] <br>"

	dat += "<b><A href='?src=\ref[src];move=[1]'>Send</A></b></center>"


	user << browse("[dat]", "window=miningshuttle;size=200x150")

/obj/machinery/computer/mining_shuttle/Topic(href, href_list)
	if(..())
		return
	usr.set_machine(src)
	src.add_fingerprint(usr)
	if(href_list["move"])
		//if(ticker.mode.name == "blob")
		//	if(ticker.mode:declared)
		//		usr << "Under directive 7-10, [station_name()] is quarantined until further notice."
		//		return

		if (!mining_shuttle_moving)
			usr << "\blue Shuttle recieved message and will be sent shortly."
			move_mining_shuttle()
		else
			usr << "\blue Shuttle is already moving."

	updateUsrDialog()

/obj/machinery/computer/mining_shuttle/attackby(obj/item/weapon/W as obj, mob/user as mob)

	if (istype(W, /obj/item/weapon/card/emag))
		src.req_access = list()
		hacked = 1
		usr << "You fried the consoles ID checking system. It's now available to everyone!"
	else
		..()

/******************************Lantern*******************************/

/obj/item/device/flashlight/lantern
	name = "lantern"
	icon_state = "lantern"
	desc = "A mining lantern."
	brightness_on = 6			// luminosity when on

/*****************************Pickaxe********************************/

/obj/item/weapon/pickaxe
	name = "pickaxe"
	icon = 'icons/obj/items.dmi'
	icon_state = "pickaxe"
	flags = FPRINT | TABLEPASS| CONDUCT
//	slot_flags = SLOT_BELT
	force = 15.0
	throwforce = 4.0
	item_state = "pickaxe"
	w_class = 4.0
	m_amt = 3750 //one sheet, but where can you make them?
	var/digspeed = 50 //moving the delay to an item var so R&D can make improved picks. --NEO
	origin_tech = "materials=1;engineering=1"
	attack_verb = list("hit", "pierced", "sliced", "attacked")
	var/drill_sound = 'sound/weapons/Genhit.ogg'
	var/drill_verb = "picking"

	var/excavation_amount = 100
	var/hardness = 1

	hammer
		name = "sledgehammer"
		//icon_state = "sledgehammer" Waiting on sprite
		desc = "A mining hammer made of reinforced metal. You feel like smashing your boss in the face with this."

	silver
		name = "silver pickaxe"
		icon_state = "spickaxe"
		item_state = "spickaxe"
		digspeed = 45
		origin_tech = "materials=3"
		desc = "This makes no metallurgic sense."
/*
	drill
		name = "mining drill" // Can dig sand as well!
		icon_state = "handdrill"
		item_state = "jackhammer"
		digspeed = 30
		origin_tech = "materials=2;powerstorage=3;engineering=2"
		desc = "Yours is the drill that will pierce through the rock walls."
		drill_verb = "drilling"
*/

	jackhammer
		name = "sonic jackhammer"
		icon_state = "jackhammer"
		item_state = "jackhammer"
		digspeed = 25 //faster than drill, but cannot dig
		hardness = 4
		origin_tech = "materials=3;powerstorage=2;engineering=2"
		desc = "Cracks rocks with sonic blasts, perfect for killing cave lizards."
		drill_verb = "hammering"

	gold
		name = "golden pickaxe"
		icon_state = "gpickaxe"
		item_state = "gpickaxe"
		digspeed = 45
		origin_tech = "materials=4"
		desc = "This makes no metallurgic sense."

	plasmacutter
		name = "plasma cutter"
		icon_state = "plasmacutter"
		item_state = "gun"
		w_class = 3.0 //it is smaller than the pickaxe
		damtype = "fire"
		digspeed = 20 //Can slice though normal walls, all girders, or be used in reinforced wall deconstruction/ light thermite on fire
		hardness = 5
		origin_tech = "materials=4;plasmatech=3;engineering=3"
		desc = "A rock cutter that uses bursts of hot plasma. You could use it to cut limbs off of xenos! Or, you know, mine stuff."
		drill_verb = "cutting"

	diamond
		name = "diamond pickaxe"
		icon_state = "dpickaxe"
		item_state = "dpickaxe"
		digspeed = 40
		origin_tech = "materials=6;engineering=4"
		desc = "A pickaxe with a diamond pick head, this is just like minecraft."
		hardness = 2

	diamonddrill //When people ask about the badass leader of the mining tools, they are talking about ME!
		name = "diamond mining drill"
		icon_state = "diamonddrill"
		item_state = "jackhammer"
		digspeed = 10 //Digs through walls, girders, and can dig up sand
		hardness = 6
		origin_tech = "materials=6;powerstorage=4;engineering=5"
		desc = "Yours is the drill that will pierce the heavens!"
		drill_sound = 'tauceti/sounds/items/drill.ogg'
		drill_verb = "drilling"

	borgdrill
		name = "cyborg mining drill"
		icon_state = "diamonddrill"
		item_state = "jackhammer"
		hardness = 5
		digspeed = 25
		desc = ""
		drill_verb = "drilling"

/*****************************Shovel********************************/

/obj/item/weapon/shovel
	name = "shovel"
	desc = "A large tool for digging and moving dirt."
	icon = 'icons/obj/items.dmi'
	icon_state = "shovel"
	flags = FPRINT | TABLEPASS| CONDUCT
	slot_flags = SLOT_BELT
	force = 8.0
	throwforce = 4.0
	item_state = "shovel"
	w_class = 3.0
	m_amt = 50
	origin_tech = "materials=1;engineering=1"
	attack_verb = list("bashed", "bludgeoned", "thrashed", "whacked")

/obj/item/weapon/shovel/spade
	name = "spade"
	desc = "A small tool for digging and moving dirt."
	icon_state = "spade"
	item_state = "spade"
	force = 5.0
	throwforce = 7.0
	w_class = 2.0


/**********************Mining car (Crate like thing, not the rail car)**************************/

/obj/structure/closet/crate/miningcar
	desc = "A mining car. This one doesn't work on rails, but has to be dragged."
	name = "Mining car (not for rails)"
	icon = 'icons/obj/storage.dmi'
	icon_state = "miningcar"
	density = 1
	icon_opened = "miningcaropen"
	icon_closed = "miningcar"

