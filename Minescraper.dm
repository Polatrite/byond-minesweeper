/*

Polatrite.Minescraper

I whipped this game up as a joke for a publicity stunt I did in January of 2010. I said I
would release a new game or a major update on every Friday in January (of which there were 5).
I coded this in about 50 minutes as a joke, to be uploaded on New Years Day. I then released
Survival - The Lost Era about 30 minutes later as the "real game" for the day, instead of a
silly Minesweeper clone.

I may document this source code better in the future, contact me if you have questions.

polatrite@gmail.com

*/



world
	icon_size = 16
	view = 35


client
	show_popup_menus = 0


mob
	Login()
		..()
		start(9, 9, 10)
	verb
		// This starts a new game, this command is called by the menu options on the menu bar
		start(width as num, height as num, mines as num)
			winset(src, "default.label", "is-visible=false")
			Start(width, height, mines)

		startmag(width as num, height as num)
			winset(src, "default.label", "is-visible=false")
			width = min(61, max(8, width))
			height = min(61, max(8, height))
			var/mines = 24.866*(width*height)**-0.256
			mines = round((width * height) / mines)
			Start(width, height, mines)



var
	count_tile
	count_empty
	count_mine
	game_active = 0

proc

	// Called whenever the player loses, shows where the mines are and freezes input
	GameOver()
		// Here we violate the usr in proc rule to annoy other experienced programmers!
		// usr is valid here because we will only ever have one user - whoever is playing
		usr << output("You lose :(","default.label")
		winset(usr, "default.label", "is-visible=true")
		for(var/obj/tile/mine/T in world)
			if(T.icon_state != "x")
				T.icon_state = "m"
		game_active = 0

	// Called whenever the player wins, celebrates and freezes input
	Win()
		// Here we violate the usr in proc rule to annoy other experienced programmers!
		// usr is valid here because we will only ever have one user - whoever is playing
		usr << output("You win!","default.label")
		winset(usr, "default.label", "is-visible=true")
		game_active = 0

	// Called to start a game in the first place
	// width - set the width of the game board in tiles
	// height - set the height of the game board in tiles
	// mines - set the number of mines to add to the field
	Start(width, height, mines)
		count_tile = 0
		count_empty = 0
		count_mine = 0

		width = min(61, max(8, width))
		height = min(61, max(8, height))
		mines = min(3700, max(1, mines))

		world.maxx = width
		world.maxy = height

		// Dynamically set the window size to accomodate the tiles without stretching
		winset(usr, "default.map", "size=[width*world.icon_size]x[height*world.icon_size]")
		winset(usr, "default", "size=[width*world.icon_size]x[height*world.icon_size]")

		// Now we put together a list of all the tiles in the game and we fill them with blank tiles
		var/turfs[] = list()
		for(var/turf/T in world)
			for(var/obj/tile/O in T)
				del(O)
			new /obj/tile(T)
			turfs += T
			count_tile++
			count_empty++

		world << count_tile

		// Now we're going to add mines to the field
		var/mi = 0

		while(mi <= mines)
			// We're going to select from our list of turfs, then place the mine
			var/turf/T = pick(turfs)
			for(var/obj/tile/O in T)
				del(O)
			new /obj/tile/mine(T)
			//world << "created at [T.x],[T.y]  ([mi])"
			// Then remove that turf from the list, so it can't be selected again
			turfs -= T
			count_empty--
			count_mine++
			mi++

		game_active = 1


obj
	icon = 'tiles.dmi'

	tile
		icon_state = "box"

		proc
			// This "uncovers" a tile to see if it is a mine or a safe tile
			// If they hit a mine, they lose
			// If all tiles are clear (except the mines) then they win
			Uncover()
				if(icon_state == "box")
					if(istype(src, /obj/tile/mine))
						icon_state = "x"
						GameOver()
					else
						icon_state = "0"
						var/count = CalculateIcon()
						count_empty--

						if(count == 0)
							// If this tile is completely clear, let's see if other tiles around are also clear and uncover them as well
							for(var/obj/tile/T in view(src, 1))
								spawn()
									T.Uncover()
					if(count_empty == 0)
						Win()

			// Allows the player to set a flag or a question mark on a tile, to specify if a mine is there
			// This has no game purpose, it is only used so the player can mark mines off
			Flag()
				if(!isnum(text2num(icon_state)))
					if(icon_state == "f")
						icon_state = "?"
					else if(icon_state == "?")
						icon_state = "box"
					else
						icon_state = "f"

			// Counts the amount of mines around the tile
			CountMines()
				var/count = 0
				for(var/obj/tile/O in view(src, 1))
					if(istype(O, /obj/tile/mine))
						count++
				return count

			// Calculates the proper icon state for the tile (1, 2, 3, 4, etc.)
			CalculateIcon()
				var/count = CountMines()
				icon_state = "[count]"
				return count


		// Almost the only interaction the player has
		// Left-click - uncovers a tile
		// Right-click - flags a tile
		Click(location, control, params)
			if(!game_active)
				return

			params = params2list(params)
			if("right" in params)
				Flag()
			else
				Uncover()


		// Ka-boom!
		mine
			icon_state = "box"

