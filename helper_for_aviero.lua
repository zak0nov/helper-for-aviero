script_name("helper-for-mia (v2.0)")
script_author("Wojciech Kaczynski")
script_version("0.4.7")
script_properties("work-in-pause", "forced-reloading-only")

-- require
local vkeys = require "vkeys" 
local rkeys = require "rkeys"
local imgui, ffi = require "mimgui", require "ffi"
local mimgui_addons = require "mimgui-addons"
local new, str = imgui.new, ffi.string
local faicons = require "fa-icons"
local font_flag = require("moonloader").font_flag
local encoding = require "encoding"
local memory = require "memory"
local xconf = require "xconf"
local gauth = require "gauth"
local https = require "ssl.https"
local wm = require('lib.windows.message')
local game_weapons = require "lib.game.weapons"
lsampev, sampev = pcall(require, "lib.samp.events")
encoding.default = "CP1251"
u8 = encoding.UTF8 
imgui.HotKey = mimgui_addons.HotKey
-- !require
 
-- configuration
local function configuration_file(directory, filename, template)
	if type(directory) ~= "string" then return false, "CF-F1" end
	if type(filename) ~= "string" then return false, "CF-F2" end
	if type(template) ~= "table" then return false, "CF-F3" end 
	if not doesDirectoryExist(directory) then createDirectory(directory) end

	local temp = xconf.new(string.format("%s//%s.json", directory, filename))
	if temp then
		temp:set_template(template)
		local result = temp:get()
		if result then return result, temp else return temp["template"], temp end
	else return false, "CF-F4" end 
end

local function configuration_loading(configuration)
	if type(configuration) ~= "table" then return false, "CF-L1" end
	if type(configuration["template"]) ~= "table" then return false, "CF-L2" end
	for index, value in ipairs(configuration["template"]) do
		local result, temp = configuration_file(configuration["directory"], value["filename"], value["template"])
		if result then
			configuration[value["configuration"]] = result
			configuration["template"][index]["xconf"] = temp
			print(string.format("Конфигурация {00cc99}%s{c0c0c0} была успешно загружена.", value["filename"]))
		else
			print(string.format("Конфигурация {ff5c33}%s{c0c0c0} не была загружена, код ошибки: #%s.", value["filename"], temp))
		end
	end return true, configuration
end

local function configuration_save(configuration, unloading)
	if type(configuration) ~= "table" then return false, "CF-S1" end
	for index, value in ipairs(configuration["template"]) do
		if value["last_update"] then
			if os.time() - value["last_update"] < 1.5 then return false, "CF-S4" else value["last_update"] = os.time() end
		else value["last_update"] = os.time() end
		if type(configuration[value["configuration"]]) ~= "table" then return false, "CF-S2" end
		if not value["xconf"] then return false, "CF-S3" end
		local result, code = value["xconf"]:set(configuration[value["configuration"]] or value["template"])
		if unloading then value["xconf"]:close() end
	end return true
end 

local configuration = {
	["directory"] = "moonloader//config//Helper for AVIERO",
	["template"] = {
		{
			["configuration"] = "CUSTOM",
			["filename"] = "HfMIA x Additional user settings",
			["xconf"] = false,
			["template"] = {
				["USERS"] = {
					["main"] = {}
				},
				["LOW_ACTION"] = {
					["male"] = {
						["healme"] = {
							["status"] = true, ["variations"] = {
								{ u8"/me вытащил аптечку, достал из неё шприц с морфином и сделал себе инъекцию в бедро." },
								{ u8"/me вытащил аптечку, достал из неё шприц с эпинефрином и сделал себе инъекцию в бедро." },
								{ u8"/me вытащил аптечку, взял из неё упаковку с трамадолом и употребил несколько таблеток." }
							}
						},
						["mask"] = {
							["status"] = true, ["variations"] = {
								{ u8"/me раскрыл поясную сумку, достал чёрную балаклаву и надел её на себя." }
							}
						},
						["unmask"] = {
							["status"] = true, ["variations"] = {
								{ u8"/do Маска всё ещё находится на лице $rpname.{my_id}." }
							}
						},
						["baton"] = {
							["status"] = true,["variations"] = {
								{ u8"/me удерживая дубинку в руке, размахнулся и нанёс удар по нарушителю." },
								{ u8"/me снял дубинку с пояса и нанёс удар достаточной силы, чтобы оглушить подозреваемого." }
							} 
						},
						["taser"] = {
							["status"] = true,["variations"] = {
								{ u8"/me выхватил тэйзер из держателя, навёлся на нарушителя и нажал на кнопку спуска." }
							}
						},
						["bullets"] = {
							["status"] = true,["variations"] = {
								{
									u8"/me достал пакет для вещдоков, сложил внутрь изъятые боеприпасы и сделал соответствующие маркировки.",
									u8"$wait 1000",
									u8"/me отложил пакет и оставил его неподалёку от себя."
								}
							}
						},
						["drugs"] = {
							["status"] = true,["variations"] = {
								{
									u8"/me достал пакет для вещдоков, сложил внутрь изъятые вещества и сделал соответствующие маркировки.",
									u8"$wait 1000",
									u8"/me отложил пакет и оставил его неподалёку от себя."
								}
							}
						},
						["weapons"] = {
							["status"] = true,["variations"] = {
								{
									u8"/me достал пакет для вещдоков, положил в него {1} и сделал соответствующие маркировки.",
									u8"$wait 1000",
									u8"/me отложил пакет и оставил его неподалёку от себя."
								}
							}
						}
					},
					["female"] = {
						["healme"] = {
							["status"] = true, ["variations"] = {
								{ u8"/me вытащила аптечку, достала из неё шприц с морфином и сделала себе инъекцию в бедро." },
								{ u8"/me вытащила аптечку, достала из неё шприц с эпинефрином и сделала себе инъекцию в бедро." },
								{ u8"/me вытащила аптечку, взяла из неё упаковку с трамадолом и употребила несколько таблеток." }
							}
						},
						["mask"] = {
							["status"] = true, ["variations"] = {
								{ u8"/me раскрыла поясную сумку, достала чёрную балаклаву и надела её на себя." }
							}
						},
						["unmask"] = {
							["status"] = true, ["variations"] = {
								{ u8"/do Маска всё ещё находится на лице $rpname.{my_id}." }
							}
						},
						["baton"] = {
							["status"] = true,["variations"] = {
								{ u8"/me удерживая дубинку в руке, размахнулась и нанесла удар по нарушителю." },
								{ u8"/me сняла дубинку с пояса и нанесла удар достаточной силы, чтобы оглушить подозреваемого." }
							}
						},
						["taser"] = {
							["status"] = true,["variations"] = {
								{ u8"/me выхватила тэйзер из держателя, навелась на нарушителя и нажала на кнопку спуска." }
							}
						},
						["bullets"] = {
							["status"] = true,["variations"] = {
								{
									u8"/me достала пакет для вещдоков, сложила внутрь изъятые боеприпасы и сделала соответствующие маркировки.",
									u8"$wait 1000",
									u8"/me отложила пакет и оставила его неподалёку от себя."
								}
							}
						},
						["drugs"] = {
							["status"] = true,["variations"] = {
								{
									u8"/me достала пакет для вещдоков, сложила внутрь изъятые вещества и сделала соответствующие маркировки.",
									u8"$wait 1000",
									u8"/me отложила пакет и оставила его неподалёку от себя."
								}
							}
						},
						["weapons"] = {
							["status"] = true,["variations"] = {
								{
									u8"/me достала пакет для вещдоков, положила в него {1} и сделала соответствующие маркировки.",
									u8"$wait 1000",
									u8"/me отложила пакет и оставила его неподалёку от себя."
								}
							}
						}
					}
				},
				["SYSTEM"] = {
					["usual"] = {
						["mh"] = {["status"] = true, ["variations"] = {}},
						["r"] = {["status"] = true, ["variations"] = {}},
						["f"] = {["status"] = true, ["variations"] = {}},
						["rn"] = {["status"] = true, ["variations"] = {}},
						["fn"] = {["status"] = true, ["variations"] = {}},
						["rep"] = {["status"] = true, ["variations"] = {}},
						["uk"] = {["status"] = true, ["variations"] = {}},
						["ak"] = {["status"] = true, ["variations"] = {}},
						["sw"] = {["status"] = true, ["variations"] = {}},
						["st"] = {["status"] = true, ["variations"] = {}},
						["sskin"] = {["status"] = true, ["variations"] = {}},
						["history"] = {["status"] = true, ["variations"] = {}},
						["lsms"] = {["status"] = true, ["variations"] = {}},
						["addbl"] = {["status"] = true, ["variations"] = {}},
						["delbl"] = {["status"] = true, ["variations"] = {}},
						["users"] = {["status"] = true, ["variations"] = {}},
						["rkinfo"] = {["status"] = true, ["variations"] = {}},
						["sms"] = {["status"] = true, ["variations"] = {}},
						["rec"] = {["status"] = true, ["variations"] = {}},
						["recn"] = {["status"] = true, ["variations"] = {}},
						["recd"] = {["status"] = true, ["variations"] = {}},
						["rtag"] = {["status"] = true, ["variations"] = {}},
						["strobes"] = {["status"] = true, ["variations"] = {}},
						["savepass"] = {["status"] = true, ["variations"] = {}},
						["infred"] = {["status"] = true, ["variations"] = {}},
						["nigvis"] = {["status"] = true, ["variations"] = {}},
						["c"] = {["status"] = true, ["variations"] = {}},
						["megafon"] = {["status"] = true, ["variations"] = {}},
						["drop_all"] = {["status"] = true, ["variations"] = {}},
						["patrol"] = {["status"] = true, ["variations"] = {}},
						["speller"] = {["status"] = true, ["variations"] = {}},
						["helper_stats"] = {["status"] = true, ["variations"] = {}},
						["goverment_news"] = {["status"] = true, ["variations"] = {}},
						["helper_online"] = {["status"] = true, ["variations"] = {}},
						["helper_snake"] = {["status"] = true, ["variations"] = {}},
						["helper_miner"] = {["status"] = true, ["variations"] = {}},
						["helper_ads"] = {["status"] = true, ["variations"] = {}},
						["lock"] = {["status"] = true, ["variations"] = {}},
						["anims"] = {["status"] = true, ["variations"] = {}},
						["helper_admins"] = {["status"] = true, ["variations"] = {}},
						["sad"] = {["status"] = true, ["variations"] = {}}
					},
					["male"] = {
						["pull"] = {
							["status"] = true, ["variations"] = {
								{
									u8"/me подойдя к подозреваемому, толкнул его, тем самым скинув с байка.",
									u8"$wait 500",
									u8"/pull {1}"
								},
								{
									u8"/me выхватил дубинку с тактического пояса и нанёс сильный удар по стеклу.",
									u8"$wait 500",
									u8"/me открыл автомобильную дверь, схватился за одежду подозреваемого и вытащил его на землю.",
									u8"$wait 500",
									u8"/pull {1}"
								}
							}
						},
						["cuff"] = {
							["status"] = true, ["variations"] = {
								{
									u8"/me завёл руки нарушителя за спину, после чего растягнул чехол для наручников.",
									u8"$wait 500",
									u8"/me достав наручники из чехла, застегнул их на запястьях преступника.",
									u8"$wait 500",
									u8"/cuff {1}"
								},
								{
									u8"/me удерживая подозреваемого, растягнул один из чехлов на тактическом поясе.",
									u8"$wait 500",
									u8"/me достал из чехла наручники и надел их на запастья подозреваемого.",
									u8"$wait 500",
									u8"/cuff {1}"
								}
							}
						},
						["uncuff"] = {
							["status"] = true, ["variations"] = {
								{
									u8"/do На запястьях $rpname.{1} находятся наручники.",
									u8"$wait 1000",
									u8"/me из чехла, что находился на поясе, достал ключ и провернул его в замке наручников.",
									u8"$wait 800",
									u8"/uncuff {1}.",
									u8"$wait 1000",
									u8"/me убрал наручники и специальный ключ по своим чехлам на поясе."
								}
							}
						},
						["arrest"] = {
							["status"] = true, ["variations"] = {
								{
									u8"/me снял рацию с плеча, поднёс её ко рту и что-то произнёс.",
									u8"$wait 1000",
									u8"/do Из департамента вышли два офицера и забрали подозреваемого с собой.",
									u8"$wait 800",
									u8"/arrest {1}",
									u8"$wait 800",
									u8"/r Подозреваемый по делу #00{1} был отправлен под арест в областную тюрьму."
								},
								{
									u8"/me снял тангету с плеча, зажал кнопку PTT и передал информацию о подозреваемом диспетчеру.",
									u8"$wait 1000",
									u8"/do Из департамента вышли два офицера и забрали подозреваемого с собой.",
									u8"$wait 800",
									u8"/arrest {1}",
									u8"$wait 800",
									u8"/r Подозреваемый по делу #00{1} был отправлен под арест в областную тюрьму."
								}
							}
						},
						["su"] = {
							["status"] = true, ["variations"] = { 
								{
									u8"/me сняв тангету с плеча, передал диспетчеру информацию о подозреваемом.",
									u8"$wait 500",
									u8"/su {1} {2} {3}"
								},
								{
									u8"/me снял тангету с плеча, зажал кнопку PTT и передал информацию о подозреваемом диспетчеру.",
									u8"$wait 500",
									u8"/su {1} {2} {3}"
								}
							}
						},
						["skip"] = {
							["status"] = true, ["variations"] = {
								{
									u8"/me из внутреннего кармана достал планшет и включил его.",
									u8"$wait 1000",
									u8"/me зашёл в одно из приложений и оформил временный пропуск на имя $rpname.{1}.",
									u8"$wait 800",
									u8"/skip {1}",
									u8"$wait 1000",
									u8"/me потушил экран планшета и убрал его обратно.",
									u8"$wait 1000",
									u8"/r Оформил временный пропуск в здания министерства на имя $rpname.{1}."
								}
							}
						},
						["clear"] = {
							["status"] = true, ["variations"] = {
								{
									u8"/me из внутреннего кармана достал планшет и включил его.",
									u8"$wait 1000",
									u8"/me зашёл в одно из приложений и нашёл личное дело $rpname.{1}.",
									u8"$wait 1000",
									u8"/me пролистал страницу в самый низ, заполнил небольшую форму и аннулировал розыск.",
									u8"$wait 800",
									u8"/clear {1}",
									u8"$wait 1000",
									u8"/me потушил экран планшета и убрал его обратно.",
									u8"$wait 1000",
									u8"/f Подозреваемый по делу #00{1} более не числится в федеральном розыске.",
									u8"$wait 800",
									u8"/f Причина: {2}."
								}
							}
						},
						["hold"] = {
							["status"] = true, ["variations"] = {
								{
									u8"/me заломав руку подозреваемого, повёл его за собой.",
									u8"$wait 500",
									u8"/hold {1}"
								},
								{
									u8"/me крепко схватил подозреваемого и потащил его за собой.",
									u8"$wait 500",
									u8"/hold {1}"
								}
							}
						},
						["ticket"] = {
							["status"] = true, ["variations"] = {
								{
									u8"/me достал блокнот, ручку и начал записывать информацию о нарушении.",
									u8"$wait 1000",
									u8"/me заполнив всю информацию о нарушении, передал бланк нарушителю.",
									u8"$wait 800",
									u8"/ticket {1} {2} {3}",
									u8"$wait 1000",
									u8"/me убрал блокнот и ручку обратно во внутренний карман."
								}
							}
						},
						["takelic"] = {
							["status"] = true, ["variations"] = {
								{
									u8"/me достал планшет, зашёл в одно из приложений и нашёл нужный транспорт.",
									u8"$wait 800",
									u8"/me получил информацию о текущем водителе и отправил запрос на изъятие лицензии.",
									u8"$wait 800",
									u8"/takelic {1} {2}.",
									u8"$wait 800",
									u8"/me потушил экран и убрал планшет обратно."
								}
							}
						},
						["putpl"] = {
							["status"] = true, ["variations"] = {
								{
									u8"/me подведя подозреваемого к автомобилю, открыл дверь и посадил его туда.",
									u8"$wait 500",
									u8"/putpl {1}"
								},
								{
									u8"/me удерживая подозреваемого, свободной рукой открыл дверь в патрульном автомобиле.",
									u8"$wait 500",
									u8"/me пригнул голову подозреваемого и усадил его в машину, закрыл за ним дверь.",
									u8"$wait 500",
									u8"/putpl {1}"
								}
							}
						},
						["rights"] = {
							["status"] = true, ["variations"] = {
								{
									u8"Вы имеете право хранить молчание. ",
									u8"$wait 1000",
									u8"Всё, что Вы скажете, может и будет использовано против Вас в суде. ",
									u8"$wait 1000",
									u8"Ваш адвокат может присутствовать при допросе. ",
									u8"$wait 1000",
									u8"Если Вы не можете оплатить услуги адвоката, он будет предоставлен вам государством.",
									u8"$wait 1000",
									u8"Если Вы не гражданин, то Вы можете связаться с консулом своей страны, прежде чем отвечать на любые вопросы.",
									u8"$wait 1000",
									u8"Всё ли вам понятно?"
								}
							}
						},
						["search"] = {
							["status"] = true, ["variations"] = {
								{
									u8"/me из внутреннего кармана достал белые, латекстные перчатки и надел их на руки.",
									u8"$wait 800",
									u8"/me осмотривает все карманы, возможные места хранение запрещённых веществ и предметов.",
									u8"$wait 500",
									u8"/search {1}"
								}
							}
						},
						["hack"] = {
							["status"] = true, ["variations"] = {
								{
									u8"/do На плечах висит рюкзак в котором лежит балончик с заморозкой.",
									u8"$wait 800",
									u8"/me скинув рюкзак с плеч, открыл его и достал балончик.",
									u8"$wait 800",
									u8"/me закрыл рюкзак и повесил его на плечи.",
									u8"$wait 800",
									u8"/me встряхнув балончик, распылил содержимое на дверной замок.",
									u8"$wait 800",
									u8"/do Под действием содержимого балончика замок промёрз и стал хрупок.",
									u8"$wait 800",
									u8"/me снял дубинку с поясного держателя и, размахнувшись, ударил тыльной частью по замку.",
									u8"$wait 500",
									u8"/hack {1}"
								}
							}
						},
						["invite"] = {
							["status"] = true, ["variations"] = {
								{
									u8"/me из внутреннего кармана достал планшет, включил его и зашёл в одно из приложений.",
									u8"$wait 1000",
									u8"/me заполнил небольшую форму и добавил новое личное дело под номером #00{1}.",
									u8"$wait 1000",
									u8"/me потушил экран планшета и убрал его обратно.",
									u8"$wait 1000",
									u8"/me достал ключ от шкафчика под номером #00{1} и передал его $rpname.{1}.",
									u8"$wait 800",
									u8"/invite {1}"
								}
							}
						},
						["uninvite"] = {
							["status"] = true, ["variations"] = {
								{
									u8"/me из внутреннего кармана достал планшет, включил его и зашёл в одно из приложений.",
									u8"$wait 1000",
									u8"/me нашёл личное дело под номером #00{1} и удалил его.",
									u8"$wait 800",
									u8"/uninvite {1} {2}",
									u8"$wait 1000",
									u8"/me потушил экран планшета и убрал его обратно.",
									u8"$wait 800",
									u8"/f Контракт с сотрудником $rpname.{1} расторгнут по причине: {2}."
								}
							}
						},
						["rang"] = {
							["status"] = true, ["variations"] = {
								{
									u8"/me из внутреннего кармана достал планшет, включил его и зашёл в одно из приложений.",
									u8"$wait 1000",
									u8"/me нашёл личное дело под номером #00{1} и изменил значение должности.",
									u8"$wait 800",
									u8"/rang {1} {2}",
									u8"$wait 1000",
									u8"/me потушил экран планшета и убрал его обратно."
								}
							}
						},
						["changeskin"] = {
							["status"] = true, ["variations"] = {
								{
									u8"/me достал ключ от шкафчика под номером #00{1} и передал его $rpname.{1}.",
									u8"$wait 800",
									u8"/changeskin {1}"
								}
							}
						},
						["ud"] = {
							["status"] = true, ["variations"] = {
								{
									u8"/me достал удостоверение, раскрыл его и показал человеку напротив.",
									u8"$wait 1000",
									u8"/do В удостоверении указано подразделение: {fraction}.",
									u8"$wait 800",
									u8"/do Личная информация: {rang} {name} [#{number}].",
									u8"$wait 1000",
									u8"/me закрыл удостоверение и убрал его обратно."
								}
							}
						},
						["pas"] = {
							["status"] = true, ["variations"] = {
								{
									u8"{greeting}, я {rang} {fraction} {name}.",
									u8"$wait 1000",
									u8"/do На груди висит значок с личным номером [#{number}].",
									u8"$wait 1000",
									u8"Будьте любезны, предъявите документы, удостоверяющие вашу личность."
								}
							}
						},
						["medhelp"] = {
							["status"] = true, ["variations"] = {
								{
									u8"/me раскрыл сумку, что висела на плече, и достал из неё необходимый препарат.",
									u8"$wait 1000",
									u8"/todo Предложив препарат больному*вот, это должно помочь в вашем случае.",
									u8"$wait 1000",
									u8"/medhelp {1} {2}"
								}
							}
						},
						["tracker"] = {
							["status"] = true, ["variations"] = {
								{
									u8"/me зажал кнопку активации GNSS-трекера до характерной вибрации включения.",
									u8"$wait 500",
									u8"/su {1} {2} GNSS-трекер"
								}
							}
						},
						["unmask"] = {
							["status"] = true, ["variations"] = {
								{
									u8"/me взявшись за маску, что находилась на лице $rpname.{1}, снял её."
								}
							}
						}
					},
					["female"] = {
						["pull"] = {
							["status"] = true, ["variations"] = {
								{
									u8"/me подойдя к подозреваемому, толкнула его, тем самым скинув с байка.",
									u8"$wait 500",
									u8"/pull {1}"
								},
								{
									u8"/me выхватила дубинку с тактического пояса и нанесла сильный удар по стеклу.",
									u8"$wait 500",
									u8"/me открыла автомобильную дверь, схватилась за одежду подозреваемого и вытащила его на землю.",
									u8"$wait 500",
									u8"/pull {1}"
								}
							}
						},
						["cuff"] = {
							["status"] = true, ["variations"] = {
								{
									u8"/me завела руки нарушителя за спину, после чего растягнула чехол для наручников.",
									u8"$wait 500",
									u8"/me достав наручники из чехла, застегнула их на запястьях преступника.",
									u8"$wait 500",
									u8"/cuff {1}"
								},
								{
									u8"/me удерживая подозреваемого, растягнула один из чехлов на тактическом поясе.",
									u8"$wait 500",
									u8"/me достала из чехла наручники и надела их на запастья подозреваемого.",
									u8"$wait 500",
									u8"/cuff {1}"
								}
							}
						},
						["uncuff"] = {
							["status"] = true, ["variations"] = {
								{
									u8"/do На запястьях $rpname.{1} находятся наручники.",
									u8"$wait 1000",
									u8"/me из чехла, что находился на поясе, достала ключ и провернула его в замке наручников.",
									u8"$wait 800",
									u8"/uncuff {1}.",
									u8"$wait 1000",
									u8"/me убрала наручники и специальный ключ по своим чехлам на поясе."
								}
							}
						},
						["arrest"] = {
							["status"] = true, ["variations"] = {
								{
									u8"/me сняла рацию с плеча, поднесла её ко рту и что-то произнесла.",
									u8"$wait 1000",
									u8"/do Из департамента вышли два офицера и забрали подозреваемого с собой.",
									u8"$wait 800",
									u8"/arrest {1}",
									u8"$wait 800",
									u8"/r Подозреваемый по делу #00{1} был отправлен под арест в областную тюрьму."
								},
								{
									u8"/me сняла тангету с плеча, зажала кнопку PTT и передала информацию о подозреваемом диспетчеру.",
									u8"$wait 1000",
									u8"/do Из департамента вышли два офицера и забрали подозреваемого с собой.",
									u8"$wait 800",
									u8"/arrest {1}",
									u8"$wait 800",
									u8"/r Подозреваемый по делу #00{1} был отправлен под арест в областную тюрьму."
								}
							}
						},
						["su"] = {
							["status"] = true, ["variations"] = {
								{
									u8"/me сняв тангету с плеча, передала диспетчеру информацию о подозреваемом.",
									u8"$wait 500",
									u8"/su {1} {2} {3}"
								},
								{
									u8"/me сняла тангету с плеча, зажала кнопку PTT и передала информацию о подозреваемом диспетчеру.",
									u8"$wait 500",
									u8"/su {1} {2} {3}"
								}
							}
						},
						["skip"] = {
							["status"] = true, ["variations"] = {
								{
									u8"/me из внутреннего кармана достала планшет и включила его.", u8"$wait 1000",
									u8"/me зашла в одно из приложений и оформила временный пропуск на имя $rpname.{1}.", u8"$wait 800",
									u8"/skip {1}", u8"$wait 1000",
									u8"/me потушила экран планшета и убрала его обратно.", u8"$wait 1000",
									u8"/r Оформила временный пропуск в здания министерства на имя $rpname.{1}."
								}
							}
						},
						["clear"] = {
							["status"] = true, ["variations"] = {
								{
									u8"/me из внутреннего кармана достала планшет и включила его.",
									u8"$wait 1000",
									u8"/me зашла в одно из приложений и нашла личное дело $rpname.{1}.",
									u8"$wait 1000",
									u8"/me пролистала страницу в самый низ, заполнила небольшую форму и аннулировала розыск.",
									u8"$wait 800",
									u8"/clear {1}",
									u8"$wait 1000",
									u8"/me потушила экран планшета и убрала его обратно.",
									u8"$wait 1000",
									u8"/f Подозреваемый по делу #00{1} более не числится в федеральном розыске.",
									u8"$wait 800",
									u8"/f Причина: {2}."
								}
							}
						},
						["hold"] = {
							["status"] = true, ["variations"] = {
								{
									u8"/me заломав руку подозреваемого, повела его за собой.",
									u8"$wait 500",
									u8"/hold {1}"
								},
								{
									u8"/me крепко схватила подозреваемого и потащила его за собой.",
									u8"$wait 500",
									u8"/hold {1}"
								}
							}
						},
						["ticket"] = {
							["status"] = true, ["variations"] = {
								{
									u8"/me достала блокнот, ручку и начала записывать информацию о нарушении.",
									u8"$wait 1000",
									u8"/me заполнив всю информацию о нарушении, передала бланк нарушителю.",
									u8"$wait 800",
									u8"/ticket {1} {2} {3}",
									u8"$wait 1000",
									u8"/me убрала блокнот и ручку обратно во внутренний карман."
								}
							}
						},
						["takelic"] = {
							["status"] = true, ["variations"] = {
								{
									u8"/me достала планшет, зашла в одно из приложений и нашла нужный транспорт.",
									u8"$wait 800",
									u8"/me получила информацию о текущем водителе и отправила запрос на изъятие лицензии.",
									u8"$wait 800",
									u8"/takelic {1} {2}.",
									u8"$wait 800",
									u8"/me потушила экран и убрала планшет обратно."
								}
							}
						},
						["putpl"] = {
							["status"] = true, ["variations"] = {
								{
									u8"/me подведя подозреваемого к автомобилю, открыла дверь и посадила его туда.",
									u8"$wait 500",
									u8"/putpl {1}"
								},
								{
									u8"/me удерживая подозреваемого, свободной рукой открыла дверь в патрульном автомобиле.",
									u8"$wait 500",
									u8"/me пригнула голову подозреваемого и усадила его в машину, закрыла за ним дверь.",
									u8"$wait 500",
									u8"/putpl {1}"
								}
							}
						},
						["rights"] = {
							["status"] = true, ["variations"] = {
								{
									u8"Вы имеете право хранить молчание. ",
									u8"$wait 1000",
									u8"Всё, что Вы скажете, может и будет использовано против Вас в суде. ",
									u8"$wait 1000",
									u8"Ваш адвокат может присутствовать при допросе. ",
									u8"$wait 1000",
									u8"Если Вы не можете оплатить услуги адвоката, он будет предоставлен вам государством.",
									u8"$wait 1000",
									u8"Если Вы не гражданин, то Вы можете связаться с консулом своей страны, прежде чем отвечать на любые вопросы.",
									u8"$wait 1000",
									u8"Всё ли вам понятно?"
								}
							}
						},
						["search"] = {
							["status"] = true, ["variations"] = {
								{
									u8"/me из внутреннего кармана достала белые, латекстные перчатки и надела их на руки.",
									u8"$wait 800",
									u8"/me осмотривает все карманы, возможные места хранение запрещённых веществ и предметов.",
									u8"$wait 500",
									u8"/search {1}"
								}
							}
						},
						["hack"] = {
							["status"] = true, ["variations"] = {
								{
									u8"/do На плечах висит рюкзак в котором лежит балончик с заморозкой.",
									u8"$wait 1000",
									u8"/me скинув рюкзак с плеч, открыла его и достал балончик.",
									u8"$wait 1000",
									u8"/me закрыла рюкзак и повесила его на плечи.",
									u8"$wait 1000",
									u8"/me встряхнув балончик, распылила содержимое на дверной замок.",
									u8"$wait 1000",
									u8"/do Под действием содержимого балончика замок промёрз и стал хрупок.",
									u8"$wait 1000",
									u8"/me сняла дубинку с поясного держателя и, размахнувшись, ударила тыльной частью по замку.",
									u8"$wait 800",
									u8"/hack {1}"
								}
							}
						},
						["invite"] = {
							["status"] = true, ["variations"] = {
								{
									u8"/me из внутреннего кармана достала планшет, включила его и зашла в одно из приложений.",
									u8"$wait 1000",
									u8"/me заполнила небольшую форму и добавила новое личное дело под номером #00{1}.",
									u8"$wait 1000",
									u8"/me потушила экран планшета и убрала его обратно.",
									u8"$wait 1000",
									u8"/me достала ключ от шкафчика под номером #00{1} и передала его $rpname.{1}.",
									u8"$wait 800",
									u8"/invite {1}"
								}
							}
						},
						["uninvite"] = {
							["status"] = true, ["variations"] = {
								{
									u8"/me из внутреннего кармана достала планшет, включила его и зашла в одно из приложений.",
									u8"$wait 1000",
									u8"/me нашла личное дело под номером #00{1} и удалила его.",
									u8"$wait 800",
									u8"/uninvite {1} {2}",
									u8"$wait 1000",
									u8"/me потушила экран планшета и убрала его обратно.",
									u8"$wait 800",
									u8"/f Контракт с сотрудником $rpname.{1} расторгнут по причине: {2}."
								}
							}
						},
						["rang"] = {
							["status"] = true, ["variations"] = {
								{
									u8"/me из внутреннего кармана достала планшет, включила его и зашла в одно из приложений.",
									u8"$wait 1000",
									u8"/me нашла личное дело под номером #00{1} и изменила значение должности.",
									u8"$wait 800",
									u8"/rang {1} {2}",
									u8"$wait 1000",
									u8"/me потушила экран планшета и убрала его обратно."
								}
							}
						},
						["changeskin"] = {
							["status"] = true, ["variations"] = {
								{
									u8"/me достала ключ от шкафчика под номером #00{1} и передала его $rpname.{1}.",
									u8"$wait 800",
									u8"/changeskin {1}"
								}
							}
						},
						["ud"] = {
							["status"] = true, ["variations"] = {
								{
									u8"/me достала удостоверение, раскрыла его и показала человеку напротив.",
									u8"$wait 1000",
									u8"/do В удостоверении указано подразделение: {fraction}.",
									u8"$wait 800",
									u8"/do Личная информация: {rang} {name} [#{number}].",
									u8"$wait 1000",
									u8"/me закрыла удостоверение и убрала его обратно."
								}
							}
						},
						["pas"] = {
							["status"] = true, ["variations"] = {
								{
									u8"{greeting}, я {rang} {fraction} {name}.",
									u8"$wait 1000",
									u8"/do На груди висит значок с личным номером [#{number}].",
									u8"$wait 1000",
									u8"Будьте любезны, предъявите документы, удостоверяющие вашу личность."
								}
							}
						},
						["medhelp"] = {
							["status"] = true, ["variations"] = {
								{
									u8"/me раскрыла сумку, что висела на плече, и достала из неё необходимый препарат.",
									u8"$wait 1000",
									u8"/todo Предложив препарат больному*вот, это должно помочь в вашем случае.",
									u8"$wait 1000",
									u8"/medhelp {1} {2}"
								}
							}
						},
						["tracker"] = {
							["status"] = true, ["variations"] = {
								{
									u8"/me зажала кнопку активации GNSS-трекерa до характерной вибрации включения.",
									u8"$wait 500",
									u8"/su {1} {2} GNSS-трекер"
								}
							}
						},
						["unmask"] = {
							["status"] = true, ["variations"] = {
								{
									u8"/me взявшись за маску, что находилась на лице $rpname.{1}, сняла её."
								}
							}
						}
					}
				}
			}
		},--]]
		{
			["configuration"] = "MANAGER",
			["filename"] = "HfMIA x Account and server manager",
			["xconf"] = false,
			["template"] = {

			}
		},
		{
			["configuration"] = "STATISTICS",
			["filename"] = "HfMIA x User statistics",
			["xconf"] = false,
			["template"] = {
				["commands"] = {},
				["message"] = 0,
				["time_using_aid_kits"] = 0,
				["time_using_mask"] = 0,
				["number_masks_used"] = 0,
				["afk_time"] = 0,
				["helper_miner"] = {},
				["police"] = {
					["cuff"] = 0,
					["uncuff"] = 0,
					["search"] = 0,
					["putpl"] = 0,
					["drugs"] = 0,
					["bullets"] = 0,
					["tickets"] = 0,
					["suspects"] = 0,
					["taser"] = 0,
					["baton"] = 0,
					["setmark"] = 0,
					["weapons_number"] = 0,
					["weapons"] = {}
				},
				["massmedia"] = {
					["ads"] = 0
				}
			}
		},
		{
			["configuration"] = "DATABASE",
			["filename"] = "HfMIA x Local database",
			["xconf"] = false,
			["template"] = {
				["player"] = {},
				["house"] = {},
				["vehicle"] = {}
			}
		},
		{
			["configuration"] = "ADS",
			["filename"] = "HfMIA x Register of ads",
			["xconf"] = false,
			["template"] = {}
		},
		{
			["configuration"] = "DOCUMENTS",
			["filename"] = "HfMIA x Regulatory legal acts",
			["xconf"] = false,
			["template"] = {
				["version"] = 0,
				["content"] = {}
			}
		},
		{
			["configuration"] = "USERS",
			["filename"] = "HfMIA x Users",
			["xconf"] = false,
			["template"] = {
				["version"] = 0,
				["content"] = {}
			}
		},
		{
			["configuration"] = "MAIN",
			["filename"] = "HfMIA x Main settings",
			["xconf"] = false,
			["template"] = {
				["information"] = {
					["name"] = u8"Wojciech Kaczynski",
					["rang"] = u8"Senior police officer",
					["fraction"] = u8"LVPD",
					["number"] = u8"04475-046",
					["sex"] = false,
					["rtag"] = u8"",
					["ftag"] = u8""
				},
				["settings"] = {
					["mask_timer"] = true,
					["aid_timer"] = true,
					["ad_blocker"] = true,
					["passport_check"] = true,
					["stroboscopes"] = true,
					["new_radio"] = true,
					["auto_buy_mandh"] = true,
					["small_acting_out"] = true,
					["weapon_acting_out"] = false,
					["auto_weapon_acting_out"] = true,
					["obtaining_weapons"] = true,
					["delay_between_deaths"] = 10,
					["chase_message"] = true,
					["patrol_assistant"]= true,
					["user_rang"] = true,
					["script_color"] = "{67BEF8}",
					["t_script_color"] = 0xBA67BEF8,
					["timestamp_color"] = 0x67BEF8,
					["line_break_by_space"] = true,
					["customization"] = false,
					["id_postfix_after_nickname"] = true,
					["quick_open_door"] = true,
					["tq_interface_x"] = 30,
					["tq_interface_y"] = 350,
					["tq_attack_officer"] = true,
					["tq_attack_civil"] = true,
					["tq_insubordination"] = true,
					["tq_escape"] = true,
					["tq_non_payment"] = true,
					["quick_lock_doors"] = true,
					["normal_speedometer_update"] = true,
					["low_fuel_level_notification"] = true,
					["waiting_time_taking_weapons"] = 1,
					["fast_interaction"] = true
				},
				["role_play_weapons"] = {
					["BRASSKNUCKLES"]    = { ["take"] = u8"", ["remove"] = u8 "" },
					["GOLFCLUB"]         = { ["take"] = u8"", ["remove"] = u8 "" },
					["NIGHTSTICK"]       = { ["take"] = u8"", ["remove"] = u8 "" },
					["KNIFE"]            = { ["take"] = u8"", ["remove"] = u8 "" },
					["BASEBALLBAT"]      = { ["take"] = u8"", ["remove"] = u8 "" },
					["SHOVEL"]           = { ["take"] = u8"", ["remove"] = u8 "" },
					["POOLCUE"]          = { ["take"] = u8"", ["remove"] = u8 "" },
					["KATANA"]           = { ["take"] = u8"", ["remove"] = u8 "" },
					["CHAINSAW"]         = { ["take"] = u8"", ["remove"] = u8 "" },
					["PURPLEDILDO"]      = { ["take"] = u8"", ["remove"] = u8 "" },
					["WHITEDILDO"]       = { ["take"] = u8"", ["remove"] = u8 "" },
					["WHITEVIBRATOR"]    = { ["take"] = u8"", ["remove"] = u8 "" },
					["SILVERVIBRATOR"]   = { ["take"] = u8"", ["remove"] = u8 "" },
					["FLOWERS"]          = { ["take"] = u8"", ["remove"] = u8 "" },
					["CANE"]             = { ["take"] = u8"", ["remove"] = u8 "" },
					["GRENADE"]          = { ["take"] = u8"", ["remove"] = u8 "" },
					["TEARGAS"]          = { ["take"] = u8"вытащил из подсумка гранату со слезоточивым газом.", ["remove"] = u8 "убрал гранату со слезоточивым газом обратно в подсумок." },
					["MOLOTOV"]          = { ["take"] = u8"", ["remove"] = u8 "" },
					["COLT45"]           = { ["take"] = u8"схатившись правой рукой за пистолет, вытащил его из кобуры.", ["remove"] = u8 "убрал пистолет обратно в кобуру и закрыл её, застегнув крепление." },
					["SILENCED"]         = { ["take"] = u8"схатившись правой рукой за пистолет, вытащил его из кобуры.", ["remove"] = u8 "убрал пистолет обратно в кобуру и закрыл её, застегнув крепление." },
					["DESERTEAGLE"]      = { ["take"] = u8"схатившись правой рукой за пистолет, вытащил его из кобуры.", ["remove"] = u8 "убрал пистолет обратно в кобуру и закрыл её, застегнув крепление." },
					["SHOTGUN"]          = { ["take"] = u8"взялся за ремень дробовика, снял его с плеча и приготовился.", ["remove"] = u8 "повесил дробовик обратно на плечо, придерживая его за ремень." },
					["SAWNOFFSHOTGUN"]   = { ["take"] = u8"", ["remove"] = u8 "" },
					["COMBATSHOTGUN"]    = { ["take"] = u8"взялся за ремень дробовика, снял его с плеча и приготовился.", ["remove"] = u8 "повесил дробовик обратно на плечо, придерживая его за ремень." },
					["UZI"]              = { ["take"] = u8"", ["remove"] = u8 "" },
					["MP5"]              = { ["take"] = u8"скинул пистолет-пулемёт HK MP-5 с плеча и взял его в руки.", ["remove"] = u8 "повесил пистолет-пулемёт HK MP-5 обратно на плечо." },
					["AK47"]             = { ["take"] = u8"", ["remove"] = u8 "" },
					["M4"]               = { ["take"] = u8"", ["remove"] = u8 "" },
					["TEC9"]             = { ["take"] = u8"", ["remove"] = u8 "" },
					["RIFLE"]            = { ["take"] = u8"", ["remove"] = u8 "" },
					["SNIPERRIFLE"]      = { ["take"] = u8"", ["remove"] = u8 "" },
					["ROCKETLAUNCHER"]   = { ["take"] = u8"", ["remove"] = u8 "" },
					["HEATSEEKER"]       = { ["take"] = u8"", ["remove"] = u8 "" },
					["FLAMETHROWER"]     = { ["take"] = u8"", ["remove"] = u8 "" },
					["MINIGUN"]          = { ["take"] = u8"", ["remove"] = u8 "" },
					["SATCHELCHARGE"]    = { ["take"] = u8"", ["remove"] = u8 "" },
					["DETONATOR"]        = { ["take"] = u8"", ["remove"] = u8 "" },
					["SPRAYCAN"]         = { ["take"] = u8"", ["remove"] = u8 "" },
					["FIREEXTINGUISHER"] = { ["take"] = u8"", ["remove"] = u8 "" },
					["CAMERA"]           = { ["take"] = u8"", ["remove"] = u8 "" },
					["NIGHTVISION"]      = { ["take"] = u8"", ["remove"] = u8 "" },
					["THERMALVISION"]    = { ["take"] = u8"", ["remove"] = u8 "" },
					["PARACHUTE"]        = { ["take"] = u8"", ["remove"] = u8 "" }
				},
				["quick_menu"] = {
					{ ["title"] = "CUFF", ["callback"] = "command_cuff"},
					{ ["title"] = "HOLD", ["callback"] = "command_hold"},
					{ ["title"] = "PUTPL", ["callback"] = "command_putpl"},
					{ ["title"] = "RIGHTS", ["callback"] = "command_rights"},
					{ ["title"] = "ARREST", ["callback"] = "command_arrest"},
					{ ["title"] = "UNCUFF", ["callback"] = "command_uncuff"},
					{ ["title"] = "SEARCH", ["callback"] = "command_search"}
				},
				["quick_criminal_code"] = {
					["attack_officer"] = { ["stars"] = 5, ["reason"] = u8"3.1 УК" },
					["attack_civil"] = { ["stars"] = 5, ["reason"] = u8"3.1 УК" },
					["insubordination"] = { ["stars"] = 4, ["reason"] = u8"31.2 УК" },
					["escape"] = { ["stars"] = 4, ["reason"] = u8"31.3 УК" },
					["non_payment"] = { ["stars"] = 3, ["reason"] = u8"25.1 УК" }
				},
				["obtaining_weapons"] = {
					["ballistic_shield"] = false,
					["police_baton"] = true,
					["pistol_with_silencer"] = false,
					["bulletproof_vest"] = true,
					["mask"] = true,
					["desert_eagle"] = true,
					["mp5"] = true,
					["m4"] = false,
					["shotgun"] = false,
					["tear_gas"] = false,
					["sniper_rifle"] = false,
					["ak47"] = false
				},
				["improved_dialogues"] = {
					["leaders"] = true,
					["find"] = true,
					["wanted"] = true,
					["clock"] = true,
					["fuel"] = true,
					["company"] = true,
					["edit"] = true,
					["shop"] = true
				},
				["characters_number"] = {
					["chat"] = 90,
					["me"] = 90,
					["do"] = 75, 
					["r"] = 80, 
					["f"] = 80, 
					["g"] = 80, 
					["fm"] = 80, 
					["m"] = 80, 
					["t"] = 80
				},
				["blacklist"] = {},
				["customization"] = {},
				["update_stars"] = {}
			}
		}
	}
}
local result, configuration = configuration_loading(configuration)
-- !configuration

-- configuration interpreter
local ti_obtaining_weapons = {
	{ ["index"] = "ballistic_shield",     ["name"] = u8"Баллистический щит",    ["status"] = function() return configuration["MAIN"]["obtaining_weapons"]["ballistic_shield"] end },
	{ ["index"] = "police_baton",         ["name"] = u8"Полицейская дубинка",   ["status"] = function() return configuration["MAIN"]["obtaining_weapons"]["police_baton"] end },
	{ ["index"] = "pistol_with_silencer", ["name"] = u8"Пистолет с глушителем", ["status"] = function() return configuration["MAIN"]["obtaining_weapons"]["pistol_with_silencer"] end },
	{ ["index"] = "bulletproof_vest",     ["name"] = u8"Бронежилет",            ["status"] = function() return configuration["MAIN"]["obtaining_weapons"]["bulletproof_vest"] end },
	{ ["index"] = "mask",                 ["name"] = u8"Балаклава",             ["status"] = function() return configuration["MAIN"]["obtaining_weapons"]["mask"] end },
	{ ["index"] = "desert_eagle",         ["name"] = u8"Desert Eagle",          ["status"] = function() return configuration["MAIN"]["obtaining_weapons"]["desert_eagle"] end },
	{ ["index"] = "mp5",                  ["name"] = u8"MP-5",                  ["status"] = function() return configuration["MAIN"]["obtaining_weapons"]["mp5"] end },
	{ ["index"] = "m4",                   ["name"] = u8"M4",                    ["status"] = function() return configuration["MAIN"]["obtaining_weapons"]["m4"] end },
	{ ["index"] = "shotgun",              ["name"] = u8"Shotgun",               ["status"] = function() return configuration["MAIN"]["obtaining_weapons"]["shotgun"] end },
	{ ["index"] = "tear_gas",             ["name"] = u8"Слезоточивый газ",      ["status"] = function() return configuration["MAIN"]["obtaining_weapons"]["tear_gas"] end },
	{ ["index"] = "sniper_rifle",         ["name"] = u8"Снайперская винтовка",  ["status"] = function() return configuration["MAIN"]["obtaining_weapons"]["sniper_rifle"] end }
}

local ti_improved_dialogues = {
	{ ["index"] = "leaders", ["name"] = u8"Диалог списка лидеров (/leaders)",         ["status"] = function() return configuration["MAIN"]["improved_dialogues"]["leaders"] end },
	{ ["index"] = "find",    ["name"] = u8"Диалог списка сотрудников (/find)",        ["status"] = function() return configuration["MAIN"]["improved_dialogues"]["find"] end },
	{ ["index"] = "wanted",  ["name"] = u8"Диалог списка разыскиваемых (/wanted)",    ["status"] = function() return configuration["MAIN"]["improved_dialogues"]["wanted"] end },
	{ ["index"] = "clock",   ["name"] = u8"Диалог службы точного времени (/c 60)",    ["status"] = function() return configuration["MAIN"]["improved_dialogues"]["clock"] end },
	{ ["index"] = "fuel",    ["name"] = u8"Диалог информации о АЗС (/fuel)",          ["status"] = function() return configuration["MAIN"]["improved_dialogues"]["fuel"] end },
	{ ["index"] = "company", ["name"] = u8"Диалог списка заказов в ТК",               ["status"] = function() return configuration["MAIN"]["improved_dialogues"]["company"] end },
	{ ["index"] = "edit",    ["name"] = u8"Диалог редактирования объявлений (/edit)", ["status"] = function() return configuration["MAIN"]["improved_dialogues"]["edit"] end }
}

local ti_system_commands = {
	{ ["index"] = "arrest",         ["path"] = {"SYSTEM", "$sex"},  ["callback"] = "command_arrest",         ["description"] = u8"Передаёт подозреваемого под арест с RP-отыгровками." },
	{ ["index"] = "cuff",           ["path"] = {"SYSTEM", "$sex"},  ["callback"] = "command_cuff",           ["description"] = u8"Одевает наручники с RP-отыгровками." },
	{ ["index"] = "uncuff",         ["path"] = {"SYSTEM", "$sex"},  ["callback"] = "command_uncuff",         ["description"] = u8"Снимает наручники с RP-отыгровками." },
	{ ["index"] = "putpl",          ["path"] = {"SYSTEM", "$sex"},  ["callback"] = "command_putpl",          ["description"] = u8"Усаживает подозреваемого в автомобиль с RP-отыгровками." },
	{ ["index"] = "rights",         ["path"] = {"SYSTEM", "$sex"},  ["callback"] = "command_rights",         ["description"] = u8"Зачитывает задержанному права." },
	{ ["index"] = "search",         ["path"] = {"SYSTEM", "$sex"},  ["callback"] = "command_search",         ["description"] = u8"Производит поверхностный обыск с RP-отыгровками." },
	{ ["index"] = "hold",           ["path"] = {"SYSTEM", "$sex"},  ["callback"] = "command_hold",           ["description"] = u8"Принудительно тащит игрока за собой с RP-отыгровкой." },
	{ ["index"] = "pull",           ["path"] = {"SYSTEM", "$sex"},  ["callback"] = "command_pull",           ["description"] = u8"Вытаскивает игрока из автомобиля." },
	{ ["index"] = "su",             ["path"] = {"SYSTEM", "$sex"},  ["callback"] = "command_su",             ["description"] = u8"Объявляет подозреваемого в розыск с RP-отыгровками." },
	{ ["index"] = "tracker",        ["path"] = {"SYSTEM", "$sex"},  ["callback"] = "command_tracker",        ["description"] = u8"Устанавливает GNSS-трекер на игрока (розыск)." },
	{ ["index"] = "skip",           ["path"] = {"SYSTEM", "$sex"},  ["callback"] = "command_skip",           ["description"] = u8"Выписывает временный пропуск игроку с RP-отыгровками." },
	{ ["index"] = "clear",          ["path"] = {"SYSTEM", "$sex"},  ["callback"] = "command_clear",          ["description"] = u8"Удаляет игрока из федерального розыска с RP-отыгровками." },
	{ ["index"] = "ticket",         ["path"] = {"SYSTEM", "$sex"},  ["callback"] = "command_ticket",         ["description"] = u8"Выписывает штрафную квитанцию с RP-отыгровками." },
	{ ["index"] = "takelic",        ["path"] = {"SYSTEM", "$sex"},  ["callback"] = "command_takelic",        ["description"] = u8"Изымает лицензию на вождение с RP-отыгровками." },
	{ ["index"] = "hack",           ["path"] = {"SYSTEM", "$sex"},  ["callback"] = "command_hack",           ["description"] = u8"Взламывает дверь дома с RP-отыгровками." },
	{ ["index"] = "ud",             ["path"] = {"SYSTEM", "$sex"},  ["callback"] = "command_ud",             ["description"] = u8"Показывает удостоверение с RP-отыгровками." },
	{ ["index"] = "pas",            ["path"] = {"SYSTEM", "$sex"},  ["callback"] = "command_pas",            ["description"] = u8"Запрашивает документы с RP-отыгровками." },
	{ ["index"] = "unmask",         ["path"] = {"SYSTEM", "$sex"},  ["callback"] = "command_unmask",         ["description"] = u8"Снимает маску с человека с RP-отыгровками." },
	{ ["index"] = "medhelp",        ["path"] = {"SYSTEM", "$sex"},  ["callback"] = "command_medhelp",        ["description"] = u8"Проводит курс платного лечения." },
	{ ["index"] = "invite",         ["path"] = {"SYSTEM", "$sex"},  ["callback"] = "command_invite",         ["description"] = u8"Принимает игрока в организацию с RP-отыгровками." },
	{ ["index"] = "uninvite",       ["path"] = {"SYSTEM", "$sex"},  ["callback"] = "command_uninvite",       ["description"] = u8"Увольняет игрока из организации с RP-отыгровками." },
	{ ["index"] = "rang",           ["path"] = {"SYSTEM", "$sex"},  ["callback"] = "command_rang",           ["description"] = u8"Изменяет должность игрока с RP-отыгровками." },
	{ ["index"] = "changeskin",     ["path"] = {"SYSTEM", "$sex"},  ["callback"] = "command_changeskin",     ["description"] = u8"Изменяет внешний вид игрока с RP-отыгровками." },
	{ ["index"] = "mh",             ["path"] = {"SYSTEM", "usual"}, ["callback"] = "command_mh",             ["description"] = u8"Открывает основное меню." },
	{ ["index"] = "patrol",         ["path"] = {"SYSTEM", "usual"}, ["callback"] = "command_patrol",         ["description"] = u8"Начинает патрулирование и открывает патрульное меню." },
	{ ["index"] = "rep",            ["path"] = {"SYSTEM", "usual"}, ["callback"] = "command_rep",            ["description"] = u8"Отправляет сообщение в репорт." },
	{ ["index"] = "uk",             ["path"] = {"SYSTEM", "usual"}, ["callback"] = "command_uk",             ["description"] = u8"Открывает уголовный кодекс." },
	{ ["index"] = "ak",             ["path"] = {"SYSTEM", "usual"}, ["callback"] = "command_ak",             ["description"] = u8"Открывает административный кодекс." },
	{ ["index"] = "sw",             ["path"] = {"SYSTEM", "usual"}, ["callback"] = "command_sw",             ["description"] = u8"Изменяет ID погоды." },
	{ ["index"] = "st",             ["path"] = {"SYSTEM", "usual"}, ["callback"] = "command_st",             ["description"] = u8"Изменяет игровое время." },
	{ ["index"] = "sskin",          ["path"] = {"SYSTEM", "usual"}, ["callback"] = "command_sskin",          ["description"] = u8"Устанавливает визуальный скин." },
	{ ["index"] = "history",        ["path"] = {"SYSTEM", "usual"}, ["callback"] = "command_history",        ["description"] = u8"Проверяет историю изменения ников." },
	{ ["index"] = "r",              ["path"] = {"SYSTEM", "usual"}, ["callback"] = "command_r",              ["description"] = u8"Отправляет сообщение в рацию." },
	{ ["index"] = "f",              ["path"] = {"SYSTEM", "usual"}, ["callback"] = "command_f",              ["description"] = u8"Отправляет сообщение в общую волну." },
	{ ["index"] = "rn",             ["path"] = {"SYSTEM", "usual"}, ["callback"] = "command_rn",             ["description"] = u8"Отправляет NRP-сообщение в рацию." },
	{ ["index"] = "fn",             ["path"] = {"SYSTEM", "usual"}, ["callback"] = "command_fn",             ["description"] = u8"Отправляет NRP-сообщение в общую волну." },
	{ ["index"] = "rtag",           ["path"] = {"SYSTEM", "usual"}, ["callback"] = "command_rtag",           ["description"] = u8"Открывает список радио тегов." },
	{ ["index"] = "megafon",        ["path"] = {"SYSTEM", "usual"}, ["callback"] = "command_megafon",        ["description"] = u8"Отправляет требование об остановке Т/С." },
	{ ["index"] = "strobes",        ["path"] = {"SYSTEM", "usual"}, ["callback"] = "command_strobes",        ["description"] = u8"Активирует стробоскопы." },
	{ ["index"] = "lock",           ["path"] = {"SYSTEM", "usual"}, ["callback"] = "command_lock",           ["description"] = u8"Умный ключ для управления автомобилем." },
	{ ["index"] = "infred",         ["path"] = {"SYSTEM", "usual"}, ["callback"] = "command_infred",         ["description"] = u8"Включает инфрокрасный режим." },
	{ ["index"] = "nigvis",         ["path"] = {"SYSTEM", "usual"}, ["callback"] = "command_nigvis",         ["description"] = u8"Включает режим ночного виденья." },
	{ ["index"] = "rec",            ["path"] = {"SYSTEM", "usual"}, ["callback"] = "command_rec",            ["description"] = u8"Обычный реконнект." },
	{ ["index"] = "recn",           ["path"] = {"SYSTEM", "usual"}, ["callback"] = "command_recn",           ["description"] = u8"Реконнект со сменой ника." },
	{ ["index"] = "recd",           ["path"] = {"SYSTEM", "usual"}, ["callback"] = "command_recd",           ["description"] = u8"Реконнект со сменой IP-адреса." },
	{ ["index"] = "savepass",       ["path"] = {"SYSTEM", "usual"}, ["callback"] = "command_savepass",       ["description"] = u8"Сохраняет пароль в менеджере аккаунтов." },
	{ ["index"] = "c",              ["path"] = {"SYSTEM", "usual"}, ["callback"] = "command_call",           ["description"] = u8"Использование телефона." },
	{ ["index"] = "sms",            ["path"] = {"SYSTEM", "usual"}, ["callback"] = "command_sms",            ["description"] = u8"Отправляет SMS-сообщение игроку." },
	{ ["index"] = "lsms",           ["path"] = {"SYSTEM", "usual"}, ["callback"] = "command_lsms",           ["description"] = u8"Отправляет SMS на последний номер." },
	{ ["index"] = "addbl",          ["path"] = {"SYSTEM", "usual"}, ["callback"] = "command_addbl",          ["description"] = u8"Добавляет человека в чёрный список (SMS)." },
	{ ["index"] = "delbl",          ["path"] = {"SYSTEM", "usual"}, ["callback"] = "command_delbl",          ["description"] = u8"Удаляет человека из чёрного списка (SMS)." },
	{ ["index"] = "drop_all",       ["path"] = {"SYSTEM", "usual"}, ["callback"] = "command_drop_all",       ["description"] = u8"Быстро выбрасывает всё оружие." },
	{ ["index"] = "speller",        ["path"] = {"SYSTEM", "usual"}, ["callback"] = "command_speller",        ["description"] = u8"Проверяет правильность написания слов." },
	{ ["index"] = "helper_stats",   ["path"] = {"SYSTEM", "usual"}, ["callback"] = "command_helper_stats",   ["description"] = u8"Статистика действий пользователя." },
	{ ["index"] = "helper_online",  ["path"] = {"SYSTEM", "usual"}, ["callback"] = "command_helper_online",  ["description"] = u8"Онлайн в каждой из организаций." },
	{ ["index"] = "helper_snake",   ["path"] = {"SYSTEM", "usual"}, ["callback"] = "command_helper_snake",   ["description"] = u8"Мини-игра 'Змейка'." },
	{ ["index"] = "helper_miner",   ["path"] = {"SYSTEM", "usual"}, ["callback"] = "command_helper_miner",   ["description"] = u8"Мини-игра 'Сапёр'." },
	{ ["index"] = "helper_ads",     ["path"] = {"SYSTEM", "usual"}, ["callback"] = "command_helper_ads",     ["description"] = u8"Лог проверенных объявлений." },
	{ ["index"] = "helper_admins",  ["path"] = {"SYSTEM", "usual"}, ["callback"] = "command_helper_admins",  ["description"] = u8"Внести администратора в список или удалить его." },
	{ ["index"] = "sad",            ["path"] = {"SYSTEM", "usual"}, ["callback"] = "command_sad",            ["description"] = u8"Ловля объявлений." },
	{ ["index"] = "goverment_news", ["path"] = {"SYSTEM", "usual"}, ["callback"] = "command_goverment_news", ["description"] = u8"Лог последних гос.новостей." },
	{ ["index"] = "rkinfo",         ["path"] = {"SYSTEM", "usual"}, ["callback"] = "command_rkinfo",         ["description"] = u8"Выводит информацию о RK." },
	{ ["index"] = "anims",          ["path"] = {"SYSTEM", "usual"}, ["callback"] = "command_animations",     ["description"] = u8"Список дополнительных анимаций." }
}

local ti_low_action = {
	{ ["index"] = "healme",   ["path"] = {"LOW_ACTION", "$sex"}, ["description"] = u8"Отыгровка при использовании аптечки." },
	{ ["index"] = "mask",     ["path"] = {"LOW_ACTION", "$sex"}, ["description"] = u8"Отыгровка при надевании маски." },
	{ ["index"] = "unmask",   ["path"] = {"LOW_ACTION", "$sex"}, ["description"] = u8"Отыгровка при исчезновении маски." },
	{ ["index"] = "baton",    ["path"] = {"LOW_ACTION", "$sex"}, ["description"] = u8"Отыгровка при использоавнии дубинки." },
	{ ["index"] = "taser",    ["path"] = {"LOW_ACTION", "$sex"}, ["description"] = u8"Отыгровка при использовании тайзера." },
	{ ["index"] = "drugs",    ["path"] = {"LOW_ACTION", "$sex"}, ["description"] = u8"Отыгровка при изъятии наркотиков." },
	{ ["index"] = "bullets",  ["path"] = {"LOW_ACTION", "$sex"}, ["description"] = u8"Отыгровка при изъятии боеприпасов." },
	{ ["index"] = "weapons",  ["path"] = {"LOW_ACTION", "$sex"}, ["description"] = u8"Отыгровка при изъятии оружия." }
}
-- !configuration interpreter

-- global value
local update_log = {
	{
		["date"] = "27.07.2022",
		u8"Обновление до версии 0.4.7",
		{
			u8"Изменён интерфейс новостей об обновлениях (наверное заметно).",
			u8"Добавлена анимация включения и отключения окон интерфейса.",
			u8"Очень важно! Теперь окончание в надписи про AFK будет корректным.",
			u8"Счётчик AFK работает теперь также корректно.",
			u8"Исправлена ошибка при работе команды /unmask."
		},
	},
	{
		["date"] = u8"До 27.07.2022",
		u8"Обновление до версии 0.4.6",
		{
			u8"Добавлена возможность оценки обновлений.",
			u8"Добавлена RP-отыгровка для снятия маски с игрока (/unmask).",
			u8"Нижние подчеркивания в никнеймах (в чате) были устранены как явление.",
			u8"Исправлены некоторые ошибки и повышена стабильность работы.",
		}
	},
	{
		["date"] = u8"До 27.07.2022",
		u8"Патч 0.4.5.2",
		{
			u8"Исправлены некоторые ошибки и повышена стабильность работы.",
		}
	},
	{
		["date"] = u8"До 27.07.2022",
		"Hotfix 0.4.5.1",
		{
			u8"Исправлены некоторые ошибки."
		}
	},
	{
		["date"] = u8"До 27.07.2022",
		u8"Обновление до версии 0.4.5",
		{
			u8"Добавлена возможность быстрого взаимодействия (с транспортом) через выделение (ПКМ).",
			u8"Добавлена возможность отключения серверной анимации с помощью /anim 0 (79).",
			u8"Добавлен редактор лимита переноса символов для отдельных чатов -> 5й пункт настроек.",
			u8"Добавлена возможность отключить быстрое взаимодействие с сущностями (B).",
			u8"Добавлены маркеры над выделенными сущностями (B) и на отметках на карте (GPS).",
			u8"Изменена чувствительность блокировщика однотипного содержания.",
			u8"Изменена функциональная часть обработки многих внутренних потоков.",
			u8"Исправлено мерцание при нажатии на пункт в быстром меню."
		}
	},
	{
		["date"] = u8"До 27.07.2022",
		u8"Обновление до версии 0.4.4",
		{
			u8"Добавлено быстрое взаимодействие с персонажами и транспортом:",
			u8"Для активации зажмите клавишу B и наведитесь на нужный вам объект взаимодействия.",
			u8"Если Вы хотите добавить новые функции для взаимодействия - напишите какие в ЛС.",
			"",
			u8"В список онлайна (/helper_online) добавлен раздел администрации.",
			u8"Администраторы будут автоматически вносится в список в зависимости от их активности.",
			u8"Добавлена команда /helper_admins для вноса администраторов в список и их удаления.",
			"",
			u8"Добавлена быстрая навигация по диалогам, использующим команды для своей активации:",
			u8"Использование: /команда X->Y->Z  (например: /gps 1-26, /price 10).",
			"",
			u8"Добавлен моментальный реконнект на сервер (/rec f).",
			u8"Добавлен более удобный сбор урожая повторным нажатием клавиши H.",
			u8"Добавлена возможность быстрого просмотра карты зажатием клавиши M.",
			"",
			u8"Внесены изменения в отображение информации на пользователе.",
			u8"Для удобства проверки объявлений добавлена команда /sad.",
			u8"Исправлена ошибка с покупкой SIM-карт и сменой цвета телефона."
		}
	},
	{
		["date"] = u8"До 27.07.2022",
		u8"Обновление до версии 0.4.3",
		{
			u8"Для отыгровки оглушения добавлены тэги {1} и {2}: id и nickname, соответственно.",
			u8"Теперь объявления от СМИ идут в общий реестр (/helper_ads).",
			u8"Изменён интерфейс редактора объявлений (/edit).",
		}
	},
	{
		["date"] = u8"До 27.07.2022",
		u8"Обновление до версии 0.4.2",
		{
			u8"Добавлена возможность редактировать статьи, используемые в быстром розыске:",
			u8"Выберите в /uk нужную вам статью, нажмите и выберите подходящее преступление.",
			"",
			u8"Добавлен список тэгов и функций для биндера.",
			u8"Добавлена возможность включать пользовательские команды в быстрое меню.",
			u8"Исправлена ошибка при отыгровке скрытия оружия."
		}
	},
	{
		["date"] = u8"До 27.07.2022",
		"Hotfix 0.4.1.1",
		{
			u8"Исправлены мелкие баги."
		}
	},
	{
		["date"] = u8"До 27.07.2022",
		u8"Обновление до версии 0.4.1",
		{
			u8"Добавлены дополнительные анимации персонажа (/anims).",
			"",
			u8"В интерфейсе патрульного ассистента список тэгов заменён на быстрое меню.",
			u8"Сообщения из этого меню будут отправляться в выбранный канал рации.",
			"",
			u8"Добавлены следующие отыгровки незначительных действий и их настройка в биндере:",
			u8"1. Отыгровка при использовании аптечек, масок;",
			u8"2. Отыгровка при оглушении игрока дубинкой или тэйзером;",
			u8"3. Отыгровка при изъятии наркотиков, боеприпасов или оружия.",
			"",
			u8"Расширены параметры, отображающиеся в статистике пользователя (/helper_stats).",
			u8"Добавлен раздел правоохранительной деятельности в статистике.",
			"",
			u8"Внесены незначительные изменения в отображении цвета пользователей в чате.",
			u8"В троеточие при разделении длинных строчек возвращена точка, поздравляем!"
		}
	},
	{
		["date"] = u8"До 27.07.2022",
		u8"Обновление до версии 0.4.0",
		{
			u8"Внесены следующие изменения в патрульного ассистента:",
			u8"1. Изменён интерфейс настройки маркировок и статуса патруля (/patrol);",
			u8"1.1. Добавлена возможность 'тихого' выхода в патруль и его завершения;",
			u8"1.2. Добавлена маркировка Unit.",
			u8"2. Изменён патрульный интерфейс;",
			u8"2.1 Добавлены кнопки активации GNSS-трекера, списка радио-тэгов;",
			u8"2.2 Добавлена кнопка переключения волны для сообщений о погоне;",
			u8"2.3 Добавлена кнопка принятия вызова в полицию;",
			u8"2.4 Добавлено название района, в котором находится юнит;",
			u8"2.5 Добавлено направление стороны света, в которую смотрит юнит.",
			"",
			u8"Прочие незначительные изменения и исправления."
		}
	},
	{
		["date"] = u8"До 27.07.2022",
		u8"Обновление до версии 0.3.9",
		{
			u8"Изменена функциональная часть и интерфейсы многих систем скрипта.",
			u8"Меню покупок в магазинах 24/7 стало удобнее.",
			u8"Внесены некоторые изменения в работу списка заказов в ТК.",
			u8"Теперь при лечении заболеваний рассчитывается время до следующего лечения."
		}
	},
	{
		["date"] = u8"До 27.07.2022",
		u8"Обновление до версии 0.3.8",
		{
			u8"Улучшено управление автомобилем при использовании FT."
		}
	},
	{
		["date"] = u8"До 27.07.2022",
		u8"Обновление до версии 0.3.7",
		{
			u8"Исправлена кастомизация timestamp'a, теперь отображается корректный цвет.",
			u8"Изменено скругление ImGUI-окон и некоторых элементов."
		}
	},
	{
		["date"] = u8"До 27.07.2022",
		u8"Обновление до версии 0.3.6",
		{
			u8"Исправлена кастомизация быстрого меню, теперь отображается корректный цвет.",
			u8"Исправлены незначительные ошибки."
		}
	},
	{
		["date"] = u8"До 27.07.2022",
		u8"Обновление до версии 0.3.5",
		{
			u8"Исправлены проблемы с общей волной рации.",
			u8"Исправлена настройка расположения быстрого розыска (теперь она работает)."
		}
	},
	{ 
		["date"] = u8"До 27.07.2022",
		u8"Обновление до версии 0.3.4",
		{
			u8"Еще очень много очень важных нововведений."
		}
	},
	{
		["date"] = u8"До 27.07.2022",
		u8"Обновление до версии 0.3.3",
		{ 
			u8"Очень много очень важных нововведений."
		}
	},
	{
		["date"] = u8"До 27.07.2022",
		u8"Обновление до версии 0.3.2",
		{
			u8"Добавлена модификация 'Умный транспорт', которая включает:",
			u8"1. Удобное открытие транспорта одной клавишей J или командой /lock.",
			u8"2. Нормальное обновление скорости транспорта на спидометре.",
			u8"3. Уведомления о низком уровне топлива."
		}
	},
	{["date"] = u8"До 27.07.2022", u8"Обновление до версии 0.3.1", {u8"Исправлены некоторые ошибки."}},
	{["date"] = u8"До 27.07.2022", u8"Обновление до версии 0.2.9", {u8"Добавлены мини-игры змейка (/helper_snake) и сапер (/helper_miner)."}},
	{["date"] = u8"До 27.07.2022", u8"Обновление до версии 0.2.8", {u8"Несколько изменена логика работы быстрого розыска."}},
	{
		["date"] = u8"До 27.07.2022",
		u8"Обновление до версии 0.2.6",
		{
			u8"Добавлена команда /helper_online для просмотра онлайна организаций.",
			u8"Внесены следующие изменения в работу команд /sms и /c:",
			u8"1. При введении дополнительного пробела после номера вызов (или смс) пройдет именно на ..",
			u8".. введенный номер. Это необходимо для новых номеров формата XX, XXX.",
			u8"Расширен функционал патрульного ассистента.",
			u8"Исправлены некоторые недоработки быстрого розыска."
		}
	},
	{
		["date"] = u8"До 27.07.2022",
		u8"Обновление до версии 0.2.5",
		{
			u8"Внесены следующие изменения в быстрый розыск:",
			u8"1. Информирование вынесено в блок отдельных интерфейсов.",
			u8" (B (англ) - включить курсор, ЛКМ - выполнить действие, ПКМ - удалить подозреваемого).",
			u8"2. Быстрый розыск (ПКМ + 5) теперь комбинирует все нарушения подозреваемого.",
			u8"3. Настройка местоположения доступна в разделе модификаций.",
			u8"Временно удалён быстрый репорт.",
			u8"Несколько изменены интерфейсы для взаимодействия с динамическими объектами."
		}
	},
	{
		["date"] = u8"До 27.07.2022",
		u8"Обновление до версии 0.2.4",
		{
			u8"Добавлены новые причины для объявления в розыск при помощи сочетания клавиш:",
			u8"1. Вооружённое нападение на любого сотрудника МЮ.",
			u8"2. Вооружённое нападение на любого гражданского.",
			u8"3. Необоснованное применение оружия.",
			u8"Добавлены пользовательские интерфейсы для взаимодействия с динамическими объектами (J).",
			u8"Расширены возможности мегафона, теперь он срабатывает на т/с МЮ, если нет иных т/с рядом.",
			u8"Добавлена сортировка списка розыскиваемых по дальности нахождения от пользователя.",
			u8"Теперь весь полученный урон будет логироваться в консоли (~)."
		}
	},
	{["date"] = u8"До 27.07.2022", u8"Обновление до версии 0.1.9", {u8"Теперь быстрое меню поддерживает пользовательские команды.", u8"Добавлен раздел модификаций."}},
	{["date"] = u8"До 27.07.2022", u8"Обновление до версии 0.1.8", {u8"Добавлен прерыватель исполнения команд (клавиша X)."}},
	{["date"] = u8"До 27.07.2022", u8"Обновление до версии 0.1.5", {u8"В тестовом режиме добавлено быстрое меню (клавиша Z)."}},
	{
		["date"] = u8"До 27.07.2022",
		u8"Обновление до версии 0.1.4",
		{
			u8"В тестовом режиме добавлена база данных (в блоке 'Панель управления').",
			u8"Улучшена система определения параметров в биндере."
		}
	},
	{
		["date"] = u8"До 27.07.2022",
		u8"Обновление до версии 0.1.2",
		{
			u8"Добавлена возможность редактировать системные команды и создавать новые вариации.",
			u8"В настройках добавлена возможность кастомизировать цвет интерфейса и префикса чата."
		}
	},
	{
		["date"] = u8"До 27.07.2022",
		u8"Обновление до версии 0.1.0",
		{
			u8"Добавлена статистика действий пользователя (/helper_stats).",
			u8"Добавлен список последних гос.новостей (/goverment_news).",
			u8"Добавлены дополнительные тэги для биндера.",
			u8"Добавлены дублирующие NRP-команды (/ncuff и т.д.)"
		}
	},
	{["date"] = u8"До 27.07.2022", u8"Обновление до версии 0.0.9", {u8"Добавлен менеджер аккаунтов.", u8"Добавлена возможность проверки правильности написания слов (/speller)."}},
	{["date"] = u8"До 27.07.2022", u8"Обновление до версии 0.0.6", {u8"Окончательно исправлена ошибка при разделении длинных строк."}},
	{["date"] = u8"До 27.07.2022", u8"Обновление до версии 0.0.5", {u8"Добавлен список дешёвых АЗС с построением маршрута до них (/fuel)."}},
	{["date"] = u8"До 27.07.2022", u8"Обновление до версии 0.0.4", {u8"Добавлен CamHack (c + 1).", u8"Улучшен разделитель строк по пробелам, теперь не кикает из игры."}},
	{["date"] = u8"До 27.07.2022", u8"Обновление до версии 0.0.3", {u8"Добавлена возможность печатать при прицеливании (правый ctrl)."}},
	{["date"] = u8"До 27.07.2022", u8"Обновление до версии 0.0.2", {u8"Добавлена система авто-обновлений."}},
	{["date"] = u8"До 27.07.2022", u8"Обновление до версии 0.0.1", {u8"Начало разработки..."}}
}

local t_vehicle_name = {"Landstalker", "Bravura", "Buffalo", "Linerunner", "Perrenial", "Sentinel", "Dumper", "Firetruck", "Trashmaster", "Stretch", "Manana", "Infernus",
	"Voodoo", "Pony", "Mule", "Cheetah", "Ambulance", "Leviathan", "Moonbeam", "Esperanto", "Taxi", "Washington", "Bobcat", "Whoopee", "BF Injection", "Hunter",
	"Premier", "Enforcer", "Securicar", "Banshee", "Predator", "Bus", "Rhino", "Barracks", "Hotknife", "Trailer", "Previon", "Coach", "Cabbie", "Stallion", "Rumpo",
	"RCBandit", "Romero","Packer", "Monster", "Admiral", "Squalo", "Seasparrow", "Pizzaboy", "Tram", "Trailer", "Turismo", "Speeder", "Reefer", "Tropic", "Flatbed",
	"Yankee", "Caddy", "Solair", "Berkley`sRCVan", "Skimmer", "PCJ-600", "Faggio", "Freeway", "RCBaron", "RCRaider", "Glendale", "Oceanic", "Sanchez", "Sparrow",
	"Patriot", "Quad", "Coastguard", "Dinghy", "Hermes", "Sabre", "Rustler", "ZR-350", "Walton", "Regina", "Comet", "BMX", "Burrito", "Camper", "Marquis", "Baggage",
	"Dozer", "Maverick", "News Chopper", "Rancher", "FBI Rancher", "Virgo", "Greenwood", "Jetmax", "Hotring", "Sandking", "Blista Compact", "Police Maverick",
	"Boxvillde", "Benson", "Mesa", "RCGoblin", "Hotring Racer A", "Hotring Racer B", "Bloodring Banger", "Rancher", "Super GT", "Elegant", "Journey", "Bike",
	"Mountain Bike", "Beagle", "Cropduster", "Stunt", "Tanker", "Roadtrain", "Nebula", "Majestic", "Buccaneer", "Shamal", "Hydra", "FCR-900", "NRG-500", "HPV1000",
	"Cement Truck", "Tow Truck", "Fortune", "Cadrona", "FBI Truck", "Willard", "Forklift", "Tractor", "Combine", "Feltzer", "Remington", "Slamvan", "Blade", "Freight",
	"Streak", "Vortex", "Vincent", "Bullet", "Clover", "Sadler", "Firetruck", "Hustler", "Intruder", "Primo", "Cargobob", "Tampa", "Sunrise", "Merit", "Utility", "Nevada",
	"Yosemite", "Windsor", "Monster", "Monster", "Uranus", "Jester", "Sultan", "Stratum", "Elegy", "Raindance", "RCTiger", "Flash", "Tahoma", "Savanna", "Bandito",
	"FreightFlat", "StreakCarriage", "Kart", "Mower", "Dune", "Sweeper", "Broadway", "Tornado", "AT-400", "DFT-30", "Huntley", "Stafford", "BF-400", "NewsVan",
	"Tug", "Trailer", "Emperor", "Wayfarer", "Euros", "Hotdog", "Club", "FreightBox", "Trailer", "Andromada", "Dodo", "RCCam", "Launch", "Police Car", "Police Car",
	"Police Car", "Police Ranger", "Picador", "SWAT", "Alpha", "Phoenix", "GlendaleShit", "SadlerShit", "Luggage A", "Luggage B", "Stairs", "Boxville", "Tiller",
	"Utility Trailer"
}

local t_vehicle_type_name = {"Автомобиль", "Мотоцикл", "Вертолёт", "Самолёт", "Прицеп", "Лодка", "Другое", "Поезд", "Велосипед"}
local tf_vehicle_type_name = {
	{"автомобиля", "мотоцикла", "вертолёта", "самолёта", "прицепа", "лодки", "", "поезда", "велосипеда"},
	{"автомобилем", "мотоциклом", "вертолётом", "самолётом", "прицепом", "лодкой", "поездом", "велосипедом"},
	{"автомобиль", "мотоцикл", "вертолёт", "самолёт", "прицеп", "лодка", "другое", "поезд", "велосипед"}
}

local t_vehicle_speed = {43, 40, 51, 30, 36, 45, 30, 41, 27, 43, 36, 61, 46, 30, 29, 53, 42, 30, 32, 41, 40, 42, 38, 27, 37,
	54, 48, 45, 43, 55, 51, 36, 26, 30, 46, 0, 41, 43, 39, 46, 37, 21, 38, 35, 30, 45, 60, 35, 30, 52, 0, 53, 43, 16, 33, 43,
	29, 26, 43, 37, 48, 43, 30, 29, 14, 13, 40, 39, 40, 34, 43, 30, 34, 29, 41, 48, 69, 51, 32, 38, 51, 20, 43, 34, 18, 27,
	17, 47, 40, 38, 43, 41, 39, 49, 59, 49, 45, 48, 29, 34, 39, 8, 58, 59, 48, 38, 49, 46, 29, 21, 27, 40, 36, 45, 33, 39, 43,
	43, 45, 75, 75, 43, 48, 41, 36, 44, 43, 41, 48, 41, 16, 19, 30, 46, 46, 43, 47, -1, -1, 27, 41, 56, 45, 41, 41, 40, 41,
	39, 37, 42, 40, 43, 33, 64, 39, 43, 30, 30, 43, 49, 46, 42, 49, 39, 24, 45, 44, 49, 40, -1, -1, 25, 22, 30, 30, 43, 43, 75,
	36, 43, 42, 42, 37, 23, 0, 42, 38, 45, 29, 45, 0, 0, 75, 52, 17, 32, 48, 48, 48, 44, 41, 30, 47, 47, 40, 41, 0, 0, 0, 29, 0, 0
}

local t_vehicle_type = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 1, 1, 1, 1, 1, 1, 1,
	3, 1, 1, 1, 1, 6, 1, 1, 1, 1, 5, 1, 1, 1, 1, 1, 7, 1, 1, 1, 1, 6, 3, 2, 8, 5, 1, 6, 6, 6, 1,
	1, 1, 1, 1, 4, 2, 2, 2, 7, 7, 1, 1, 2, 3, 1, 7, 6, 6, 1, 1, 4, 1, 1, 1, 1, 9, 1, 1, 6, 1,
	1, 3, 3, 1, 1, 1, 1, 6, 1, 1, 1, 3, 1, 1, 1, 7, 1, 1, 1, 1, 1, 1, 1, 9, 9, 4, 4, 4, 1, 1, 1,
	1, 1, 4, 4, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 7, 1, 1, 1, 1, 8, 8, 7, 1, 1, 1, 1, 1, 1, 1,
	1, 3, 1, 1, 1, 1, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 7, 1, 1, 1, 1, 8, 8, 7, 1, 1, 1, 1, 1, 4,
	1, 1, 1, 2, 1, 1, 5, 1, 2, 1, 1, 1, 7, 5, 4, 4, 7, 6, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 5, 5, 5, 1, 5, 5
}

local fraction_color = {
	[4278190335] = {"Министерство внутренних дел"},
	[4291624704] = {"Правительство"},
	[4294927872] = {"ТВ-Радио"},
	[301989887] = {"Безработные"},
	[4278220149] = {"Russian Mafia"},
	[4288230246] = {"La Cosa Nostra"},
	[4278229248] = {"Grove Street"},
	[4291559679] = {"The Ballas"},
	[4284901119] = {"The Rifa"},
	[4294927974] = {"Министерство здравоохранения"},
	[4288243251] = {"Министерство обороны"},
	[4290445312] = {"Yakuza"},
	[4278242559] = {"Varios Los Aztecas"},
	[4294954240] = {"Los Santos Vagos"}
}
-- !global value

-- local value
local invite_player_id
local invite_rang
local passport_check
local report_text
local smart_suspect_id
local last_sms_number
local global_reconnect_status
local infrared_vision
local night_vision
local delay_between_deaths
local b_stroboscopes = false
local pricel
local flymode
local last_on_send_value
local entered_password
local entered_to_save_password
local need_update_configuration
local targeting_player = -1
local pause_start
local was_pause
local global_break_command
local global_command_handler
local last_damage_id
local viewing_documents = false
local is_script_exit
local script_is_alive = true
local im_weapons_selected = 24
local global_samp_cursor_status = false
local destroy_samp_cursor = true
local global_radio = "r"
local open_menu_map = false
local player_status = 0
local fast_reconnect = false
local targeting_vehicle = false
local delay_take_ads
local time_take_ads
local current_update_scores

local ui_meta = {
    __index = function(self, v)
        if v == "switch" then
            local switch = function(bool)
                if self.process and self.process:status() ~= "dead" then
                    return false -- // Предыдущая анимация ещё не завершилась!
                end
                self.timer = os.clock()
                self.state = not self.state

                self.process = lua_thread.create(function()
                    local bringFloatTo = function(from, to, start_time, duration)
                        local timer = os.clock() - start_time
                        if timer >= 0.00 and timer <= duration then
                            local count = timer / (duration / 100)
                            return count * ((to - from) / 100)
                        end
                        return (timer > duration) and to or from
                    end

                    while true do wait(0)
                        local a = bringFloatTo(0.00, 1.00, self.timer, self.duration)
                        self.alpha = self.state and a or 1.00 - a
                        if a == 1.00 then break end
                    end
                end)
                return true -- // Состояние окна изменено!
            end
            return switch
        end
 
        if v == "alpha" then
            return self.state and 1.00 or 0.00
        end
    end
}

local t_mimgui_render = {
	["main_menu"] = { ["state"] = false, ["duration"] = 0.15, ["close"] = 1 },
	["setting_patrol"] = { ["state"] = false, ["duration"] = 0.15, ["close"] = 1 },
	["patrol_bar"] = { ["state"] = false, ["duration"] = 0.15, ["close"] = 0 },
	["quick_menu"] = { ["state"] = false, ["duration"] = 0.0, ["close"] = 1 },
	["editor_ads"] = { ["state"] = false, ["duration"] = 0.0, ["close"] = 0 },
	["regulatory_legal_act"] = { ["state"] = false, ["duration"] = 0.15, ["close"] = 1 },
	["quick_tags"] = { ["state"] = false, ["duration"] = 0.0, ["close"] = 1 },
	["animations"] = { ["state"] = false, ["duration"] = 0.15, ["close"] = 1 },
	["editor_quick_suspect"] = { ["state"] = false, ["duration"] = 0.15, ["close"] = 2 },
	["tags_information"] = { ["state"] = false, ["duration"] = 0.15, ["close"] = 2 },
	["helper_ads"] = { ["state"] = false, ["duration"] = 0.15, ["close"] = 1 },
	["update_scores"] = { ["state"] = false, ["duration"] = 0.15, ["close"] = 2 }
}

for index, value in pairs(t_mimgui_render) do
	setmetatable(t_mimgui_render[index], ui_meta)
end

local string_found = {
	new.char[256](),
	new.char[256](),
	new.char[256](),
	new.char[256]()
}

local font_size = new.int(0)
local t_delay_between_deaths = new.int(configuration["MAIN"]["settings"]["delay_between_deaths"])
local imgui_patrol_list = new('const char* const [11]', {"Unit", "L (Lincoln)", "A (Adam)", "M (Mary)", "C (Charley)", "D (David)", "H (Henry)", "ASD (Air Support Division)", "SUPERVISOR"})
local imgui_patrol_current = new.int(0)
local imgui_patrol_number = new.char[256]()
local imgui_custom_float = new.float(0)
local imgui_editor_ads = new.char[256]()
local imgui_quick_editor_ads = new.char[256]()
local im_role_play_action_weapon_take = new.char[512](configuration["MAIN"]["role_play_weapons"]["DESERTEAGLE"]["take"])
local im_role_play_action_weapon_remove = new.char[512](configuration["MAIN"]["role_play_weapons"]["DESERTEAGLE"]["remove"])
local im_float_color = configuration["MAIN"]["customization"]["Button"] and new.float[3](configuration["MAIN"]["customization"]["Button"]["r"], configuration["MAIN"]["customization"]["Button"]["g"], configuration["MAIN"]["customization"]["Button"]["b"]) or new.float[3]()
local im_input_command = new.char[256]() 
local im_input_parametrs = new.int(0)
local im_update_scores = new.int(0)
local im_update_text = new.char[1000]()

local t_last_requirement = {}
local t_need_to_purchase = {}
local t_last_suspect_parametrs = {}
local patrol_status = {}
local t_patrol_status = {}
local t_accept_the_offer
local convert_patrol_list = {"Unit", "L", "A", "M", "C", "D", "H", "ASD", "SUPERVISOR"}
local camera = {}
local t_map_markers = {}
local goverment_news = {}
local quick_menu_list = {}
local quick_tags_menu = {}
local global_wanted = {}
local t_smart_suspects = {}
local global_snake_game
local global_miner_game
local list_of_orders = {value = {}}
local last_used_vehicle_key = {type = false, time = false}
local t_smart_vehicle = {speedometr_id = false, vehicle = {}, fuel = {}, enter = {}}
local t_quick_ads = {}
local t_quick_editor_ads = {}
local t_quick_editor_update
local procedures_performed
local product_delivery_status = 0
local documents = {}
local global_current_document
local t_player_text = {}
local t_suspects_stars = {}
local t_patrol_area = { ["area"] = "Неизвестно", ["clock"] = os.clock() }
local t_accept_police_call
local player_animation
local time_quick_suspect
local t_smart_found_ads = {}
local was_start_harvesting
local t_quick_menu
local last_send_command
local t_static_time = { os.date("%H"), os.date("%M"), false }
local t_entity_marker = {}

local t_database_search = {
	{ ["index"] = u8"Игроки", ["matches"] = 0, ["content"] = {} },
	{ ["index"] = u8"Недвижимость", ["matches"] = 0, ["content"] = {} }
 }

local main_menu_navigation = {
    ["current"] = 1,
    ["list"] = { u8"Новости", u8"Настройки", u8"База данных", u8"Биндер", u8"Менеджер аккаунтов" }
}

local settings_menu_navigation = {
	["current"] = 1
}

local binder_menu_navigation = {
	["current"] = 1
}

local t_input_user_information = {
	{ ["index"] = "##user_name",     ["hint"] = u8"Имя и фамилия",         ["value"] = new.char[256](configuration["MAIN"]["information"]["name"]),     ["path"] = { "MAIN", "information", "name" } },
	{ ["index"] = "##user_rang",     ["hint"] = u8"Должность",             ["value"] = new.char[256](configuration["MAIN"]["information"]["rang"]),     ["path"] = { "MAIN", "information", "rang" } },
	{ ["index"] = "##user_fraction", ["hint"] = u8"Организация",           ["value"] = new.char[256](configuration["MAIN"]["information"]["fraction"]), ["path"] = { "MAIN", "information", "fraction" } },
	{ ["index"] = "##user_number",   ["hint"] = u8"Личный номер",          ["value"] = new.char[256](configuration["MAIN"]["information"]["number"]),   ["path"] = { "MAIN", "information", "number" } },
	{ ["index"] = "##user_rteg",     ["hint"] = u8"Префикс в рацию",       ["value"] = new.char[256](configuration["MAIN"]["information"]["rtag"]),     ["path"] = { "MAIN", "information", "rtag" } },
	{ ["index"] = "##user_fteg",     ["hint"] = u8"Префикс в общую волну", ["value"] = new.char[256](configuration["MAIN"]["information"]["ftag"]),     ["path"] = { "MAIN", "information", "ftag" } },
}

local t_basic_settings = {
	{ ["index"] = "##sex",               ["description"] = u8"Режим женских отыгровок",                   ["path"] = { "MAIN", "information", "sex" } },
	{ ["index"] = "##patrol_assistant",  ["description"] = u8"Патрульный ассистент",                      ["path"] = { "MAIN", "settings", "patrol_assistant" } },
	{ ["index"] = "##obtaining_weapons", ["description"] = u8"Автоматическое получение оружия на складе", ["path"] = { "MAIN", "settings", "obtaining_weapons" } },
	{ ["index"] = "##weapon_acting_out", ["description"] = u8"RP-отыгровки при использовании оружия",     ["path"] = { "MAIN", "settings", "weapon_acting_out" } },
	{ ["index"] = "##small_acting_out",  ["description"] = u8"RP-отыгровки незначительных действий",      ["path"] = { "MAIN", "settings", "small_acting_out" } }
}

local t_improved_dialogs = {
	{ ["index"] = "##dialog_leaders", ["description"] = u8"Диалог списка лидеров",            ["path"] = { "MAIN", "improved_dialogues", "leaders" } },
	{ ["index"] = "##dialog_find",    ["description"] = u8"Диалог списка сотрудников",        ["path"] = { "MAIN", "improved_dialogues", "find" } },
	{ ["index"] = "##dialog_wanted",  ["description"] = u8"Диалог списка разыскиваемых",      ["path"] = { "MAIN", "improved_dialogues", "wanted" } },
	{ ["index"] = "##dialog_clock",   ["description"] = u8"Диалог службы точного времени",    ["path"] = { "MAIN", "improved_dialogues", "clock" } },
	{ ["index"] = "##dialog_company", ["description"] = u8"Диалог списка заказов в ТК",       ["path"] = { "MAIN", "improved_dialogues", "company" } },
	{ ["index"] = "##dialog_edit",    ["description"] = u8"Диалог редактирования объявлений", ["path"] = { "MAIN", "improved_dialogues", "edit" } },
	{ ["index"] = "##dialog_shop",    ["description"] = u8"Диалог покупок в магазинах 24/7",  ["path"] = { "MAIN", "improved_dialogues", "shop" } }
}

local t_automatic_receipt_weapons = {
	{ ["index"] = "ballistic_shield",     ["description"] = u8"Баллистический щит",    ["path"] = { "MAIN", "obtaining_weapons", "ballistic_shield" } },
	{ ["index"] = "police_baton",         ["description"] = u8"Полицейская дубинка",   ["path"] = { "MAIN", "obtaining_weapons", "police_baton" } },
	{ ["index"] = "pistol_with_silencer", ["description"] = u8"Пистолет с глушителем", ["path"] = { "MAIN", "obtaining_weapons", "pistol_with_silencer" } },
	{ ["index"] = "bulletproof_vest",     ["description"] = u8"Бронежилет",            ["path"] = { "MAIN", "obtaining_weapons", "bulletproof_vest" } },
	{ ["index"] = "mask",                 ["description"] = u8"Балаклава",             ["path"] = { "MAIN", "obtaining_weapons", "mask" } },
	{ ["index"] = "desert_eagle",         ["description"] = u8"Desert Eagle",          ["path"] = { "MAIN", "obtaining_weapons", "desert_eagle" } },
	{ ["index"] = "mp5",                  ["description"] = u8"MP-5",                  ["path"] = { "MAIN", "obtaining_weapons", "mp5" } },
	{ ["index"] = "m4",                   ["description"] = u8"M4",                    ["path"] = { "MAIN", "obtaining_weapons", "m4" } },
	{ ["index"] = "shotgun",              ["description"] = u8"Shotgun",               ["path"] = { "MAIN", "obtaining_weapons", "shotgun" } },
	{ ["index"] = "tear_gas",             ["description"] = u8"Слезоточивый газ",      ["path"] = { "MAIN", "obtaining_weapons", "tear_gas" } },
	{ ["index"] = "sniper_rifle",         ["description"] = u8"Снайперская винтовка",  ["path"] = { "MAIN", "obtaining_weapons", "sniper_rifle" } },
	-- { ["index"] = "ak47",                 ["description"] = u8"Автомат Калашникова",   ["path"] = { "MAIN", "obtaining_weapons", "ak47" } }
}

local t_limit_characters = {
	{ ["index"] = "##chat", ["description1"] = u8"Обычный чат", ["description2"] = "chat", ["path"] = { "MAIN", "characters_number", "chat" } },
	{ ["index"] = "##me",   ["description1"] = u8"RP-чат",      ["description2"] = "/me",  ["path"] = { "MAIN", "characters_number", "me" } },
	{ ["index"] = "##do",   ["description1"] = u8"RP-чат",      ["description2"] = "/do",  ["path"] = { "MAIN", "characters_number", "do" } },
	{ ["index"] = "##r",    ["description1"] = u8"Рация",       ["description2"] = "/r",   ["path"] = { "MAIN", "characters_number", "r" } },
	{ ["index"] = "##f",    ["description1"] = u8"Общая волна", ["description2"] = "/f",   ["path"] = { "MAIN", "characters_number", "f" } },
	{ ["index"] = "##g",    ["description1"] = u8"Чат группы",  ["description2"] = "/g",   ["path"] = { "MAIN", "characters_number", "g" } },
	{ ["index"] = "##fm",   ["description1"] = u8"Чат семьи",   ["description2"] = "/fm",  ["path"] = { "MAIN", "characters_number", "fm" } },
	{ ["index"] = "##m",    ["description1"] = u8"Мегафон",     ["description2"] = "/m",   ["path"] = { "MAIN", "characters_number", "m" } },
	{ ["index"] = "##t",    ["description1"] = u8"Прямой эфир", ["description2"] = "/t",   ["path"] = { "MAIN", "characters_number", "t" } }
}

local t_role_play_weapons = {
	[0]  = false,
	[1]  = { ["index"] = "BRASSKNUCKLES",    ["description"] = "Brass Knuckles" },
	[2]  = { ["index"] = "GOLFCLUB",         ["description"] = "Golf Club" },
	[3]  = { ["index"] = "NIGHTSTICK",       ["description"] = "Nightstick" },
	[4]  = { ["index"] = "KNIFE",            ["description"] = "Knife" },
	[5]  = { ["index"] = "BASEBALLBAT",      ["description"] = "Baseball Bat" },
	[6]  = { ["index"] = "SHOVEL",           ["description"] = "Shovel" },
	[7]  = { ["index"] = "POOLCUE",          ["description"] = "Pool Cue" },
	[8]  = { ["index"] = "KATANA",           ["description"] = "Katana" },
	[9]  = { ["index"] = "CHAINSAW",         ["description"] = "Chainsaw" },
	[10] = { ["index"] = "PURPLEDILDO",      ["description"] = "Purple Dildo" },
	[11] = { ["index"] = "WHITEDILDO",       ["description"] = "Dildo" },
	[12] = { ["index"] = "WHITEVIBRATOR",    ["description"] = "Vibrator" },
	[13] = { ["index"] = "SILVERVIBRATOR",   ["description"] = "Silver Vibrator" },
	[14] = { ["index"] = "FLOWERS",          ["description"] = "Flowers" },
	[15] = { ["index"] = "CANE",             ["description"] = "Cane" },
	[16] = { ["index"] = "GRENADE",          ["description"] = "Grenade" },
	[17] = { ["index"] = "TEARGAS",          ["description"] = "Tear Gas" },
	[18] = { ["index"] = "MOLOTOV",          ["description"] = "Molotov Cocktail" },
	[19]  = false,
	[20]  = false,
	[21]  = false,
	[22] = { ["index"] = "COLT45",           ["description"] = "9mm" },
	[23] = { ["index"] = "SILENCED",         ["description"] = "Silenced 9mm" },
	[24] = { ["index"] = "DESERTEAGLE",      ["description"] = "Desert Eagle" },
	[25] = { ["index"] = "SHOTGUN",          ["description"] = "Shotgun" },
	[26] = { ["index"] = "SAWNOFFSHOTGUN",   ["description"] = "Sawnoff Shotgun" },
	[27] = { ["index"] = "COMBATSHOTGUN",    ["description"] = "Combat Shotgun" },
	[28] = { ["index"] = "UZI",              ["description"] = "Micro Uzi" },
	[29] = { ["index"] = "MP5",              ["description"] = "MP5" },
	[30] = { ["index"] = "AK47",             ["description"] = "AK-47" },
	[31] = { ["index"] = "M4",               ["description"] = "M4" },
	[32] = { ["index"] = "TEC9",             ["description"] = "Tec-9" },
	[33] = { ["index"] = "RIFLE",            ["description"] = "Country Rifle" },
	[34] = { ["index"] = "SNIPERRIFLE",      ["description"] = "Sniper Rifle" },
	[35] = { ["index"] = "ROCKETLAUNCHER",   ["description"] = "RPG" },
	[36] = { ["index"] = "HEATSEEKER",       ["description"] = "HS Rocket" },
	[37] = { ["index"] = "FLAMETHROWER",     ["description"] = "Flamethrower" },
	[38] = { ["index"] = "MINIGUN",          ["description"] = "Minigun" },
	[39] = { ["index"] = "SATCHELCHARGE",    ["description"] = "Satchel Charge" },
	[40] = { ["index"] = "DETONATOR",        ["description"] = "Detonator" },
	[41] = { ["index"] = "SPRAYCAN",         ["description"] = "Spraycan" },
	[42] = { ["index"] = "FIREEXTINGUISHER", ["description"] = "Fire Extinguisher" },
	[43] = { ["index"] = "CAMERA",           ["description"] = "Camera" },
	[44] = { ["index"] = "NIGHTVISION",      ["description"] = "Night Vis Goggles" },
	[45] = { ["index"] = "THERMALVISION",    ["description"] = "Thermal Goggles" },
	[46] = { ["index"] = "PARACHUTE",        ["description"] = "Parachute" }
}

local t_player_renders = {
	{ ["index"] = "##mask_timer", ["description"] = u8"Таймер времени использования маски",    ["path"] = { "MAIN", "settings", "mask_timer" } },
	{ ["index"] = "##aid_timer",  ["description"] = u8"Таймер анимации использования аптечки", ["path"] = { "MAIN", "settings", "aid_timer" } }
}

local t_chat_and_enter = {
	{ ["index"] = "##ad_blocker",                ["description"] = u8"Выносить объявления от СМИ в консоль",        ["path"] = { "MAIN", "settings", "ad_blocker" } },
	{ ["index"] = "##new_radio",                 ["description"] = u8"Изменённый цвет для рации и общей волны",     ["path"] = { "MAIN", "settings", "new_radio" } },
	{ ["index"] = "##chase_message",             ["description"] = u8"Сообщение в рацию во время погони (ПКМ + 3)", ["path"] = { "MAIN", "settings", "chase_message" } },
	{ ["index"] = "##id_postfix_after_nickname", ["description"] = u8"ID игроков в чате",                           ["path"] = { "MAIN", "settings", "id_postfix_after_nickname" } },
	{ ["index"] = "##line_break_by_space",       ["description"] = u8"Разделение строки на месте пробела",          ["path"] = { "MAIN", "settings", "line_break_by_space" } }
}

local t_automatics_actions = {
	{ ["index"] = "##passport_check",   ["description"] = u8"Автоматическая проверка документов (/pas)", ["path"] = { "MAIN", "settings", "passport_check" } },
	{ ["index"] = "##auto_buy_mandh",   ["description"] = u8"Автоматическая покупка масок и аптечек",    ["path"] = { "MAIN", "settings", "auto_buy_mandh" } },
	{ ["index"] = "##quick_open_door",  ["description"] = u8"Кнопки быстрого взаимодействия с дверьми",  ["path"] = { "MAIN", "settings", "quick_open_door" } },
	{ ["index"] = "##quick_lock_doors", ["description"] = u8"Открытие дверей транспорта 'умным ключом'", ["path"] = { "MAIN", "settings", "quick_lock_doors" } },
	{ ["index"] = "##fast_interaction", ["description"] = u8"Быстрое взаимодействие с сущностями (B)",   ["path"] = { "MAIN", "settings", "fast_interaction" } }
}

local t_transport_improvements = {
	{ ["index"] = "##stroboscopes",                ["description"] = u8"Стробоскопы (ПКМ + H)",                  ["path"] = { "MAIN", "settings", "stroboscopes" } },
	{ ["index"] = "##normal_speedometer_update",   ["description"] = u8"Нормальное обновление спидометра",       ["path"] = { "MAIN", "settings", "normal_speedometer_update" } },
	{ ["index"] = "##low_fuel_level_notification", ["description"] = u8"Уведомления при низком уровне топлива",  ["path"] = { "MAIN", "settings", "low_fuel_level_notification" } }
}

local t_quick_suspect = {
	{ ["index"] = "##attack_officer",  ["description"] = u8"Нападение на офицера",                ["path"] = { "MAIN", "settings", "tq_attack_officer" } },
	{ ["index"] = "##attack_civil",    ["description"] = u8"Нападение на гражданского",           ["path"] = { "MAIN", "settings", "tq_attack_civil" } },
	{ ["index"] = "##insubordination", ["description"] = u8"Неповиновение законным требованиям",  ["path"] = { "MAIN", "settings", "tq_insubordination" } },
	{ ["index"] = "##escape",          ["description"] = u8"Избегание задержания, побег",         ["path"] = { "MAIN", "settings", "tq_escape" } },
	{ ["index"] = "##non_payment",     ["description"] = u8"Отказ от уплаты штрафа",              ["path"] = { "MAIN", "settings", "tq_non_payment" } }
}

local t_tags_and_functions = {
	{ ["index"] = "$wait",         ["description"] = u8"Задержка между действиями в мс ($wait 1000)" },
	{ ["index"] = "$chat",         ["description"] = u8"Визуальное сообщение в чат ($chat Hello)" },
	{ ["index"] = "$script",       ["description"] = u8"Вызов команды ($script MAIN, cuff, {my_id})" },
	{ ["index"] = "$global",       ["description"] = u8"Вызов функции ($global command_drop_all, 0)" },
	{ ["index"] = "$rpname.ID",    ["description"] = u8"Получить nickname в рп-формате ($rpname.{my_id})" },
	{ ["index"] = "$name.ID",      ["description"] = u8"Получить nickname ($name.{1})" },
	{ ["index"] = "{targeting}",   ["description"] = u8"ID выделенного игрока (зелёный треугольник)"},
	{ ["index"] = "{suspect}",     ["description"] = u8"ID первого подорезваемого из быстрого розыска"},
	{ ["index"] = "{my_id}",       ["description"] = u8"Ваш ID"},
	{ ["index"] = "{greeting}",    ["description"] = u8"Приветствие в зависимости от времени суток"},
	{ ["index"] = "{last_number}", ["description"] = u8"Номер игрока, который отправил Вам SMS"},
	{ ["index"] = "{name}",        ["description"] = u8"Ваше имя и фамилия из настроек"},
	{ ["index"] = "{rang}",        ["description"] = u8"Ваша должность из настроек"},
	{ ["index"] = "{fraction}",    ["description"] = u8"Ваше подразделение из настроек"},
	{ ["index"] = "{number}",      ["description"] = u8"Ваш личный номер из настроек"},
	{ ["index"] = "{date}",        ["description"] = u8"Дата в формате ДЕНЬ.МЕСЯЦ.ГОД"},
	{ ["index"] = "{day}",         ["description"] = u8"День месяца (от 1 до 31)"},
	{ ["index"] = "{month}",       ["description"] = u8"Номер месяца (от 1 до 12)"},
	{ ["index"] = "{year}",        ["description"] = u8"Год в формате XX"},
	{ ["index"] = "{year4}",       ["description"] = u8"Год в формате XXXX"},
	{ ["index"] = "{day_of_week}", ["description"] = u8"День недели (англ.)"},
	{ ["index"] = "{time}",        ["description"] = u8"Время в формате ЧАС:МИНУТА:СЕКУНДА"},
	{ ["index"] = "{hour}",        ["description"] = u8"Час (от 0 до 23)"},
	{ ["index"] = "{minute}",      ["description"] = u8"Минута (от 0 до 59)"},
	{ ["index"] = "{second}",      ["description"] = u8"Секунда (от 0 до 59)"}
}

local t_animations = {
	{
		["title"] = "SWAT",
		{ "SWAT", "GNSTWALL_INJURD" },
		{ "SWAT", "JMP_WALL1M_180" },
		{ "SWAT", "RAIL_FALL" },
		-- { "SWAT", "RAIL_FALL_CRAWL" },
		{ "SWAT", "SWT_BREACH_01" },
		{ "SWAT", "SWT_BREACH_02" },
		{ "SWAT", "SWT_BREACH_03" },
		{ "SWAT", "SWT_GO" },
		{ "SWAT", "SWT_LKT" },
		{ "SWAT", "SWT_STY" },
		{ "SWAT", "SWT_VENT_01" },
		{ "SWAT", "SWT_VENT_02" },
		-- { "SWAT", "SWT_VNT_SHT_DIE" },
		{ "SWAT", "SWT_VNT_SHT_IN" },
		-- { "SWAT", "SWT_VNT_SHT_LOOP" },
		{ "SWAT", "SWT_WLLPK_L" },
		{ "SWAT", "SWT_WLLPK_L_BACK" },
		{ "SWAT", "SWT_WLLPK_R" },
		{ "SWAT", "SWT_WLLPK_R_BACK" },
		{ "SWAT", "SWT_WLLSHOOT_IN_L" },
		{ "SWAT", "SWT_WLLSHOOT_IN_R" },
		{ "SWAT", "SWT_WLLSHOOT_OUT_L" },
		{ "SWAT", "SWT_WLLSHOOT_OUT_R" }
	},
	{
		["title"] = "COLT45",
		{ "COLT45", "2GUNS_CROUCHFIRE" },
		{ "COLT45", "COLT45_CROUCHFIRE" },
		{ "COLT45", "COLT45_CROUCHRELOAD" },
		{ "COLT45", "COLT45_FIRE" },
		{ "COLT45", "COLT45_FIRE_2HANDS" },
		{ "COLT45", "COLT45_RELOAD" },
		{ "COLT45", "SAWNOFF_RELOAD" },
	},
	{
		["title"] = "COP_AMBIENT",
		{ "COP_AMBIENT", "COPBROWSE_IN" },
		{ "COP_AMBIENT", "COPBROWSE_LOOP" },
		{ "COP_AMBIENT", "COPBROWSE_NOD" },
		{ "COP_AMBIENT", "COPBROWSE_OUT" },
		{ "COP_AMBIENT", "COPBROWSE_SHAKE" },
		{ "COP_AMBIENT", "COPLOOK_IN" },
		{ "COP_AMBIENT", "COPLOOK_LOOP" },
		{ "COP_AMBIENT", "COPLOOK_NOD" },
		{ "COP_AMBIENT", "COPLOOK_OUT" },
		{ "COP_AMBIENT", "COPLOOK_SHAKE" },
		{ "COP_AMBIENT", "COPLOOK_THINK" },
		{ "COP_AMBIENT", "COPLOOK_WATCH" },
		{ "COP_DVBYZ", "COP_DVBY_B" },
		{ "COP_DVBYZ", "COP_DVBY_FT" },
		{ "COP_DVBYZ", "COP_DVBY_L" },
		{ "COP_DVBYZ", "COP_DVBY_R" },
	},
	{
		["title"] = "POLICE",
		{ "POLICE", "COPTRAF_AWAY" },
		{ "POLICE", "COPTRAF_COME" },
		{ "POLICE", "COPTRAF_LEFT" },
		{ "POLICE", "COPTRAF_STOP" },
		{ "POLICE", "COP_GETOUTCAR_LHS" },
		{ "POLICE", "COP_MOVE_FWD" },
		{ "POLICE", "CRM_DRGBST_01" },
		{ "POLICE", "DOOR_KICK" },
		{ "POLICE", "PLC_DRGBST_01" },
		{ "POLICE", "PLC_DRGBST_02" },
	},
	{
		["title"] = "SHOTGUN",
		{ "SHOTGUN", "SHOTGUN_CROUCHFIRE" },
		{ "SHOTGUN", "SHOTGUN_FIRE" },
		{ "SHOTGUN", "SHOTGUN_FIRE_POOR" },
	},
	{
		["title"] = "BEACH",
		{ "BEACH", "BATHER" },
		{ "BEACH", "LAY_BAC_LOOP" },
		{ "BEACH", "PARKSIT_M_LOOP" },
		{ "BEACH", "PARKSIT_W_LOOP" },
		{ "BEACH", "SITNWAIT_LOOP_W" }
	}
}
-- !local value

-- const

local abbreviated_codes = {
	{ "cod 0", "Говорит $m, CODE 0, требуется срочная помощь в район $p, недоступен.", "CODE 0", function() patrol_status["status"] = "0" end },
	{ "cod 1", "Говорит $m, CODE 1, требуется помощь в район $p, недоступен.", "CODE 1", function() patrol_status["status"] = "1" end },
	{ "cod 11", "Говорит $m, занимаю маркировку $m, CODE 1-1, доступен.", "CODE 1-1",  function() patrol_status["status"] = "4" end },
	{ "cod 13", "Говорит $m, завершаю патрулирование, освобождаю текущую маркировку, CODE 1-3, недоступен.", "CODE 1-3", function() patrol_status["status"] = "4" end },
	{ "cod 14", "Говорит $m, доставляю подозреваемого в департамент, CODE 1-4, недоступен.", "CODE 1-4", function() patrol_status["status"] = "1-4" end },
	{ "tf 55", "Говорит $m, провожу траффик-стоп '55, CODE 4, нахожусь в районе $p, недоступен.", "TF 55", function() patrol_status["status"] = "4" end },
	{ "tf 66", "Говорит $m, провожу траффик-стоп '66, CODE 3, нахожусь в районе $p, недоступен.", "TF 66", function() patrol_status["status"] = "3" end },
	{ "s 99", "Говорит $m, 10-99 по последней ситуации, CODE 4, доступен.", "10-99", function() patrol_status["status"] = "4" end }
}

local handler_tags = {
	{ "{greeting}", function() return greeting_depending_on_the_time() end },
	{ "{my_id}", function()
			local result, player_id = sampGetPlayerIdByCharHandle(playerPed)
			return result and player_id or 0
		end
	},
	{ "{name}", function() return u8:decode(configuration["MAIN"]["information"]["name"]) end },
	{ "{rang}", function() return u8:decode(configuration["MAIN"]["information"]["rang"]) end },
	{ "{fraction}", function() return u8:decode(configuration["MAIN"]["information"]["fraction"]) end },
	{ "{number}", function() return u8:decode(configuration["MAIN"]["information"]["number"]) end },
	{ "{targeting}", function() return targeting_player end },
	{ "{suspect}", function() return t_smart_suspects[1] and t_smart_suspects[1]["player_id"] or "-1" end },
	{ "{date}", function() return os.date("%d.%m.%Y") end },
	{ "{day}", function() return os.date("%d") end },
	{ "{month}", function() return os.date("%m") end },
	{ "{year}", function() return os.date("%y") end },
	{ "{year4}", function() return os.date("%Y") end },
	{ "{day_of_week}", function() return os.date("%A") end },
	{ "{time}", function() return os.date("%H:%M:%S") end },
	{ "{hour}", function() return os.date("%H") end },
	{ "{minute}", function() return os.date("%M") end },
	{ "{second}", function() return os.date("%S") end },
	{ "{last_number}", function() return tostring(last_sms_number) end }
}

local t_fuel_station = {
	[0] = {x = 1941.6208496094, y = -1769.3118896484, z = 13.640625},
	[1] = {x = 1000.4306640625, y = -937.40905761719, z = 42.328125},
	[2] = {x = 655.79522705078, y = -564.87713623047, z = 15.903906822205},
	[3] = {x = -2244.2521972656, y = -2560.7556152344, z = 31.488304138184},
	[4] = {x = -1606.1212158203, y = -2713.9748535156, z = 48.099872589111},
	[5] = {x = -2025.7088623047, y = 156.74633789063, z = 29.0390625},
	[6] = {x = -2410.0356445313, y = 976.25115966797, z = 45.425102233887},
	[7] = {x = -1675.8916015625, y = 412.89123535156, z = 6.7495198249817},
	[8] = {x = -1328.3719482422, y = 2677.5046386719, z = 49.629257202148},
	[9] = {x = -91.141693115234, y = -1169.1536865234, z = 1.9911493062973},
	[10] = {x = 1381.5281982422, y = 459.86477661133, z = 20.345203399658},
	[11] = {x = 612.16564941406, y = 1695.0120849609, z = 6.5607070922852},
	[12] = {x = -1471.1192626953, y = 1864.021484375, z = 32.202579498291},
	[13] = {x = 2202.7873535156, y = 2474.4704589844, z = 10.390445709229},
	[14] = {x = 2115.2702636719, y = 920.24621582031, z = 10.383306503296},
	[15] = {x = 2639.9272460938, y = 1106.2498779297, z = 10.390357971191},
	[16] = {x = 2147.9555664063, y = 2747.6809082031, z = 10.389307022095},
	[17] = {x = 1595.7800292969, y = 2199.4895019531, z = 10.382888793945},
	[18] = {x = -1530.6135253906, y = -1590.4718017578, z = 37.813919067383},
	[19] = {x = -220.83619689941, y = 2601.8581542969, z = 62.273105621338},
	[20] = {x = -214.10762023926, y = -277.92230224609, z = 0.99726545810699}
}

local t_points_completed_orders = {
	["Нефтезавод"] = {x = 284.40417480469, y = 1407.1119384766, z = 11.404602050781},
	["Порт LS"] = {x = 2231, y = -2463.6225585938, z = 22},
	["Порт SF"] = {x = -1742.3614501953, y = 177.56506347656, z = 22},
	["Ферма"] = {x = -1138, y = -1115.8880615234, z = 22},
	["Rubetek"] = {x = 1381.4666748047, y = 1153.1119384766, z = 22},
	["Банковский порт"] = {x = -1433.5958251953, y = 932.98681640625, z = 22},
	["Темпл Драйв"] = {x = 2517.513671875, y = -2090.3413085938, z = 22},
	["Склад Блуберри"] = {x = 245.41979980469, y = 0.9088134765625, z = 22},
	["Бэйсайд"] = {x = -2462.689453125, y = 2216, z = 22},
	["Тьерра-Робада"] = {x = -528.59582519531, y = 2597.1430664063, z = 22},
	["Эвери Констракшн"] = {x = 316.73229980469, y = -249.68505859375, z = 22},
	["Казино Камелот"] = {x = 2384.2021484375, y = 987.99755859375, z = 22},
	["Не помню :с"] = {x = 2252.2751464844, y = 16.205505371094, z = 22},
	["Завод продуктов"] = {x = -223.46765136719, y = -208.41381835938, z = 22},
	["Трансляционная станция"] = {x = -2507.7958984375, y = -614.10131835938, z = 22},
	["Энджел Пэйн"] = {x = -2240.171875, y = -2319.3356933594, z = 22},
	["Лесхоз"] = {x = -632.69989013672, y = -54.59716796875, z = 22},
	["Северный склад ЛВ"] = {x = 2252.0161132813, y = 2764.0727539063, z = 11.8203125},
	["Хим. завод"] = {x = -1022.4123535156, y = -667.88330078125, z = 22},
	["Склад Монтгомерри"] = {x = 1425.5716552734, y = 257.6455078125, z = 22},
	["Лас-Пайасадас"] = {x = -260.29895019531, y = 2608, z = 22},
	["Стадион"] = {x = 1377.3615722656, y = 2234.0827636719, z = 11.8203125},
	["Лос-Сантос Интернейшнл"] = {x = 1392.0515136719, y = -2327.5341796875, z = 22},
	["Восточная стройка"] = {x = 2618.6728515625, y = 823.76037597656, z = 22},
	["Уэтстоун"] = {x = -1399.46875, y = -1488, z = 22},
	["Океанский порт"] = {x = 2801.140625, y = -2482, z = 22},
	["ЖК Силовичок"] = {x = -2089.4995117188, y = 389.857421875, z = 22},
	["АЭС"] = {x = 2790, y = 2577.3935546875, z = 22},
	["Автосалон СФ"] = {x = -1912.9560546875, y = 276.67614746094, z = 42.046875},
	["Склад Мидл"] = {x = -534.25561523438, y = -492.33703613281, z = 22},
	["Лодочный пирс"] = {x = -2951.6318359375, y = 459.0556640625, z = 22},
	["Восточный склад"] = {x = 2857.5891113281, y = 904.39288330078, z = 11.75},
	["Трамвайное депо"] = {x = -2219.3962402344, y = 415.94116210938, z = 22},
	["Округ Ред"] = {x = 1558.5964355469, y = 27.0146484375, z = 22}
}

local maximum_number_of_characters = function() return configuration["MAIN"]["characters_number"] end
local lcons = {}
local w, h = getScreenResolution()
local imgui_script_name = u8"всегда радуйтесь"
-- !const

 -- mimgui
 local function loadIconicFont(fontSize)
	-- Load iconic font in merge mode
	local config = imgui.ImFontConfig()
	config.MergeMode = true
	config.PixelSnapH = true
	local iconRanges = new.ImWchar[3](faicons.min_range, faicons.max_range, 0)
	imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(faicons.get_font_data_base85(), fontSize, config, iconRanges)
end

imgui.OnInitialize(function()
	local glyph_ranges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()

	imgui.GetIO().Fonts:Clear()
	imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. "\\tahomabd.ttf", 13, nil, glyph_ranges)
	font_size[0] = imgui.GetIO().Fonts.ConfigData.Data[0].SizePixels

	loadIconicFont(font_size[0])
	apply_custom_style()

	button_punishment = { [0] = faicons["ICON_TIMES_CIRCLE"], [1] = faicons["ICON_TICKET"], [2] = faicons["ICON_ID_CARD"], [3] = faicons["ICON_EMPIRE"] }

	register_quick_menu()
end)


imgui.OnFrame(function() return t_mimgui_render["update_scores"]["alpha"] > 0.0 end,
function(self)
	self["HideCursor"] = not t_mimgui_render["update_scores"]["state"]
	imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, t_mimgui_render["update_scores"]["alpha"])
	imgui.SetNextWindowPos(imgui.ImVec2(w / 2, h / 2), imgui.Cond.FirstUseEver)
	imgui.SetNextWindowSize(imgui.ImVec2(350, 180))
	imgui.Begin("##update_scores", nil, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar)

		imgui.BeginChild("##update-version-info", imgui.ImVec2(90, 31)) -- версия
			imgui.SetCursorPos(imgui.ImVec2(5, 5))
			imgui.Button(u8"Оценка", imgui.ImVec2(80, 21))
			-- imgui.Button(update_log[current_update_scores][1], imgui.ImVec2(80, 21))
		imgui.EndChild()

		imgui.SameLine() -- same

		imgui.BeginChild("##update-scores", imgui.ImVec2(185, 31)) -- оценка
			imgui.SetCursorPos(imgui.ImVec2(5, 5))

			imgui.CustomButton(string.format("%s##update_scores", faicons["ICON_HEART"]), imgui.ImVec2(25, 21))
			imgui.SameLine(nil, 5) -- same

			imgui.PushItemWidth(145)
			imgui.SliderInt("##update_scores_number", im_update_scores, 0, 5)
			imgui.Hint("##update-scores-number-hint", u8"Оцените это обновление от 0 до 5 баллов.")
		imgui.EndChild()

		imgui.SameLine() -- same

		imgui.BeginChild("##update-send", imgui.ImVec2(35, 31)) -- отправка 
			imgui.SetCursorPos(imgui.ImVec2(5, 5))
			if imgui.Button(faicons["ICON_PAPER_PLANE"], imgui.ImVec2(25, 21)) then 
				configuration["MAIN"]["update_stars"][current_update_scores] = im_update_scores[0]

				local result, player_id = sampGetPlayerIdByCharHandle(playerPed)
				local player_nickname = sampGetPlayerName(player_id)

				local send = {
					u8(string.format("%s (version %s, serial %s):", player_nickname, thisScript().version, player_serial_number)),
					u8(string.format("Пользователь оценил обновление %s.", update_log[current_update_scores][1])),
					u8(string.format("Оценка: %s балл(-ов)", im_update_scores[0])),
					string.format(u8"Комментарий: %s", string.match(str(im_update_text), "(%S+)") and str(im_update_text) or "nil")
				}

				send_bot(table.concat(send, "\n"))
				chat("Ваша оценка была успешно отправлена.")

				t_mimgui_render["update_scores"][0] = false
				current_update_scores = false

				if not need_update_configuration then need_update_configuration = os.clock() end
				return false
			end
			imgui.Hint("##update-scores-send-hint", u8"Нажмите, чтобы отправить оценку.")
		imgui.EndChild()

		imgui.BeginChild("##update-text", imgui.ImVec2(330, 123)) -- комментарий
			imgui.SetCursorPos(imgui.ImVec2(5, 5))
			imgui.InputTextMultiline("##update-text-input", im_update_text, 1000, imgui.ImVec2(320, 113))
			imgui.Hint("##update-scores-text-hint", u8"Здесь Вы можете оставить свой комментарий (необязательно).")
		imgui.EndChild()
	imgui.End()
	imgui.PopStyleVar()
end)

imgui.OnFrame(function() return t_mimgui_render["animations"]["alpha"] > 0.0 end, -- анимации
function(player)
	player["HideCursor"] = not t_mimgui_render["animations"]["state"]
	imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, t_mimgui_render["animations"]["alpha"])
	imgui.SetNextWindowPos(imgui.ImVec2(w / 2, h / 2), imgui.Cond.FirstUseEver)
	imgui.SetNextWindowSize(imgui.ImVec2(350, 450))
	imgui.Begin("##animations", nil, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar)
		imgui.SetCursorPos(imgui.ImVec2(10, 10))
		imgui.BeginChild("##animations-", imgui.ImVec2(330, 430))
			imgui.SetCursorPosY(5) -- fix Y
			for index, library in ipairs(t_animations) do
				if imgui.TreeNodeStr(u8(library["title"])) then
					for index, animation in ipairs(library) do
						if imgui.Button(u8(animation[2])) then
							play_animation(animation[1], animation[2])
							if not player_animation then create_player_text(3) end
							player_animation = animation
						end

						if index ~= #library then
							if math.fmod(index, 2) ~= 0 then imgui.SameLine() end -- same
						end
					end
					imgui.TreePop()
				end
			end
		imgui.EndChild()

	imgui.End()
	imgui.PopStyleVar()
end)

imgui.OnFrame(function() return t_mimgui_render["quick_menu"]["alpha"] > 0.0 end, -- быстрое меню
function(player)
	player["HideCursor"] = not t_mimgui_render["quick_menu"]["state"]
	imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, t_mimgui_render["quick_menu"]["alpha"])
	imgui.SetNextWindowBgAlpha(0.0)
	imgui.SetNextWindowPos(imgui.ImVec2(w / 2, h / 2), nil, imgui.ImVec2(0.5, 0.5))
	imgui.SetNextWindowSize(imgui.ImVec2(400, 400))
	imgui.Begin("##quickmenu", nil, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoResize)

		if t_quick_menu then
			displaying_quick_menu(t_quick_menu)
		else 
			displaying_quick_menu(quick_menu_list)
		end

	imgui.End()
	imgui.PopStyleVar()
end)

imgui.OnFrame(function() return t_mimgui_render["quick_tags"]["alpha"] > 0.0 end, -- быстрое меню
function(self)
	self["HideCursor"] = not t_mimgui_render["quick_tags"]["state"]
	imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, t_mimgui_render["quick_tags"]["alpha"])
	imgui.SetNextWindowBgAlpha(0.0)
	imgui.SetNextWindowPos(imgui.ImVec2(w / 2, h / 2), nil, imgui.ImVec2(0.5, 0.5))
	imgui.SetNextWindowSize(imgui.ImVec2(400, 400))
	imgui.Begin("##quicktags", nil, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoResize)

		if displaying_quick_menu(quick_tags_menu) then t_mimgui_render["quick_tags"]["switch"]() end

	imgui.End()
	imgui.PopStyleVar()
end)

imgui.OnFrame(function() return t_mimgui_render["helper_ads"]["alpha"] > 0.0 end, -- реестр объявлений
function(player)
	player["HideCursor"] = not t_mimgui_render["helper_ads"]["state"]
	imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, t_mimgui_render["helper_ads"]["alpha"])
	imgui.SetNextWindowPos(imgui.ImVec2(w / 2, h / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	imgui.SetNextWindowSize(imgui.ImVec2(460, 277))
	imgui.Begin(string.format("%s##15", imgui_script_name), nil, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)

	imgui.BeginChild("##поиск_по_реестру", imgui.ImVec2(440, 30))
		imgui.SetCursorPos(imgui.ImVec2(5, 5))
		imgui.PushItemWidth(430)
		if imgui.InputTextWithHint("##editorads", u8"Часть или полное объявление", string_found[4], 500) then
			t_smart_found_ads = smart_ads(string_found[4])
		end
	imgui.EndChild()

	imgui.BeginChild("##реестр", imgui.ImVec2(440, 200))
		if #t_smart_found_ads == 0 then
			imgui.SetCursorPosY(90) -- fix Y
			imgui.CenterText(u8"Не найдено ни одного объявления :(")
		else
			imgui.SetCursorPosY(5) -- fix Y
			for index, value in ipairs(t_smart_found_ads) do
				imgui.SetCursorPosX(5) -- fix X
				imgui.Button(string.format("%s## matches-%s", value["matches"], index), imgui.ImVec2(35, 20)) -- число совпадений
				imgui.SameLine() -- same

				imgui.CustomButton(string.format("%s## ads-%s", value["corrected"], index))
				imgui.Hint(string.format("##sft-hint-%s", index), value["received"])
			end
		end
	imgui.EndChild()

	imgui.End()
	imgui.PopStyleVar()
end)

imgui.OnFrame(function() return t_mimgui_render["editor_ads"]["alpha"] > 0.0 end, -- редактор объявлений СМИ
function(player)
	player["HideCursor"] = not t_mimgui_render["editor_ads"]["state"]
	imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, t_mimgui_render["editor_ads"]["alpha"])
	imgui.SetNextWindowPos(imgui.ImVec2(w / 2, h / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	imgui.SetNextWindowSize(imgui.ImVec2(460, 307))
	imgui.Begin(string.format("%s##7", imgui_script_name), nil, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)
		local input = t_quick_ads["ad"]
		if not input then return end
 
		imgui.BeginChild("##author_and_ads", imgui.ImVec2(440, 57))
			imgui.SetCursorPos(imgui.ImVec2(5, 5))
			imgui.CustomButton(u8"Объявление от")
			imgui.SameLine(nil, 5) -- same 
			if t_quick_ads["rp_nickname"] then 
				imgui.Button(t_quick_ads["author"])
			else
				imgui.CustomButton(t_quick_ads["author"], nil, imgui.ImVec4(1.0, 0.3, 0.3, 1.0))
				imgui.Hint("##non-roleplay-nickname", u8"Этот nickname имеет NRP-формат.")
			end

			imgui.SetCursorPosX(5) -- fix X
			imgui.CustomButton(u8(input))
		imgui.EndChild()

		imgui.BeginChild("##editor_ads", imgui.ImVec2(440, 57))
			imgui.SetCursorPos(imgui.ImVec2(5, 5))
			imgui.PushItemWidth(430)
			if imgui.InputTextWithHint("##editorads", u8"Отредактированная версия объявления", imgui_editor_ads, 500) then
				imgui_quick_editor_ads = imgui_editor_ads
				t_quick_editor_update = os.clock()
			end

			imgui.SetCursorPosX(9) -- fix X
			if imgui.Button(u8"Принять") then
				sampSendDialogResponse(t_quick_ads["dialog_id"], 1, 0, u8:decode(str(imgui_editor_ads)))

				table.insert(configuration["ADS"], {
					received_ad = u8(t_quick_ads["ad"]), corrected_ad = str(imgui_editor_ads), author = t_quick_ads["author"],
					button = 1, start_of_verification = t_quick_ads["time"], finish_of_verification = os.time()
				})

				if not need_update_configuration then need_update_configuration = os.clock() end

				t_mimgui_render["editor_ads"]["switch"]()
				t_quick_ads = {}
			end imgui.SameLine()

			if imgui.Button(u8"Отклонить") then
				sampSendDialogResponse(t_quick_ads["dialog_id"], 0, 0, u8:decode(str(imgui_editor_ads)))

				table.insert(configuration["ADS"], {
					received_ad = u8(t_quick_ads["ad"]), corrected_ad = str(imgui_editor_ads), author = t_quick_ads["author"],
					button = 0, start_of_verification = t_quick_ads["time"], finish_of_verification = os.time()
				})

				if not need_update_configuration then need_update_configuration = os.clock() end

				t_mimgui_render["editor_ads"]["switch"]()
				t_quick_ads = {}
			end imgui.SameLine()

			if imgui.Button(u8"Перенести в поле редактора") then
				imgui_editor_ads = new.char[256](u8(input))
			end imgui.SameLine()

			if imgui.Button(u8"Правописание") then
				local result = command_speller(u8:decode(str(imgui_editor_ads)))
				if result and table.maxn(result) > 0 then
					local ad = str(imgui_editor_ads)
					for index, value in ipairs(result) do ad = string.gsub(ad, value[1], value[2]) end
					imgui_editor_ads = new.char[256](ad)
				end
			end

			imgui.Hint("##speller", u8"Нажмите, чтобы проверить правильность написания слов.")
		imgui.EndChild()

		imgui.BeginChild("##поиск_по_реестру.1", imgui.ImVec2(440, 30))
			imgui.SetCursorPos(imgui.ImVec2(5, 5))
			imgui.PushItemWidth(430)
			if imgui.InputTextWithHint("##editor_ads.1", u8"Поиск похожего объявления в реестре", imgui_quick_editor_ads, 500) or t_quick_editor_update then
				t_quick_editor_update = false
				t_quick_editor_ads = smart_ads(imgui_quick_editor_ads)
			end
		imgui.EndChild()

		imgui.BeginChild("##реестр.2", imgui.ImVec2(440, 105))
			if #t_quick_editor_ads == 0 then
				imgui.SetCursorPosY(45) -- fix Y
				imgui.CenterText(u8"Не найдено ни одного объявления :(")
			else
				imgui.SetCursorPosY(5) -- fix Y
				for index, value in ipairs(t_quick_editor_ads) do
					imgui.SetCursorPosX(5) -- fix X
					imgui.Button(string.format("%s## matches-%s", value["matches"], index), imgui.ImVec2(35, 20)) -- масса совпадений
					imgui.SameLine(nil, 5) -- same

					local corrected = u8:decode(value["corrected"])
					if string.len(corrected) > 80 then corrected = string.sub(corrected, 1, 80) .. "..." end

					if imgui.CustomButton(string.format("%s## ads-%s", u8(corrected), index)) then
						imgui_editor_ads = new.char[256](value["corrected"])
					end
					imgui.Hint(string.format("##sft-hint-%s", index), value["received"])
				end
			end
		imgui.EndChild()
	imgui.End()
	imgui.PopStyleVar()
end)

imgui.OnFrame(function() return t_mimgui_render["patrol_bar"]["alpha"] > 0.0 end, -- патрульный интерфейс (зачем?)
function(player)
	player["HideCursor"] = not t_mimgui_render["patrol_bar"]["state"]
	imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, t_mimgui_render["patrol_bar"]["alpha"])
	imgui.SetNextWindowPos(imgui.ImVec2(40, h / 2), imgui.Cond.FirstUseEver)
	imgui.SetNextWindowSize(imgui.ImVec2(270, 100))
	imgui.Begin(string.format("%s##6", imgui_script_name), nil, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar)
		player.HideCursor = not global_samp_cursor_status

		imgui.SetCursorPos(imgui.ImVec2(10, 10))
		imgui.BeginChild("##main", imgui.ImVec2(100, 80))
			local alltime = math.floor(os.clock() - (patrol_status["clock"] or 0))
			local second = math.fmod(alltime, 60)

			local mark = string.format("%s-%s", patrol_status["mark"], patrol_status["number"])
			local code = patrol_status["status"]

			imgui.SetCursorPos(imgui.ImVec2(5, 5))
			imgui.Button(string.format(u8"%s:%s", math.floor(alltime / 60), (second < 10 and "0" .. second or second)), imgui.ImVec2(90, 20))

			imgui.SetCursorPosX(5) -- fix X
			imgui.Button(string.format("%s", mark), imgui.ImVec2(90, 20))

			imgui.SetCursorPosX(5) -- fix X
			imgui.Button(string.format("CODE %s", code), imgui.ImVec2(90, 20))
		imgui.EndChild()

		imgui.SameLine()

		imgui.BeginChild("##action", imgui.ImVec2(140, 80))
			imgui.SetCursorPos(imgui.ImVec2(5, 5))
			if imgui.Button(faicons["ICON_MAP_MARKER"], imgui.ImVec2(25, 20)) then
				local result, player_id = sampGetPlayerIdByCharHandle(playerPed)
				command_tracker(string.format("%s %s", player_id, 1))
			end
			imgui.Hint("##gnss-tracker", u8"Нажмите, чтобы активировать GNSS-трекер.")

			imgui.SameLine() -- same

			if imgui.Button(faicons["ICON_TAGS"], imgui.ImVec2(25, 20)) then
				mimgui_window("quick_tags")
			end
			imgui.Hint("##patrol_tags", u8"Нажмите, чтобы открыть список кодов для рации.")

			imgui.SameLine() -- same

			if global_radio == "r" then
				if imgui.Button("R", imgui.ImVec2(25, 20)) then global_radio = "f" end
				imgui.Hint("##radio", u8"Нажмите, чтобы изменить волну для сообщений.")
			else
				if imgui.Button("F", imgui.ImVec2(25, 20)) then global_radio = "r" end
				imgui.Hint("##radio", u8"Нажмите, чтобы изменить волну для сообщений.")
			end

			imgui.SameLine() -- same

			if t_accept_police_call then
				if imgui.CustomButton(faicons["ICON_VOLUME_CONTROL_PHONE"], imgui.ImVec2(25, 20), imgui.ImVec4(0.8, 0.36, 0.36, 1.00)) then
					sampSendChat(string.format("/to %s", t_accept_police_call["id"]))
					t_accept_police_call = false
				end

				imgui.Hint("##police_call", u8"Нажмите, чтобы принять вызов.")
			else
				imgui.Button(faicons["ICON_PHONE"], imgui.ImVec2(25, 20))
				imgui.Hint("##police_call", u8"Пока что не поступало никаких вызовов.")
			end

			if os.clock() - t_patrol_area["clock"] > 1 then t_patrol_area["area"] = u8(calculateZone()) end
			imgui.SetCursorPos(imgui.ImVec2(5, 33))
			imgui.Button(t_patrol_area["area"], imgui.ImVec2(130, 20))

			imgui.SetCursorPosY(60)
			local direction, angel = patrol_direction()
			imgui.CenterText(string.format("%s %s (%s)", faicons["ICON_COMPASS"], u8(direction), angel))
		imgui.EndChild()
	imgui.End()
	imgui.PopStyleVar()
end)

imgui.OnFrame(function() return t_mimgui_render["setting_patrol"]["alpha"] > 0.0 end, -- настройка патрульного ассистента
function(self)
	self["HideCursor"] = not t_mimgui_render["setting_patrol"]["state"]
	imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, t_mimgui_render["setting_patrol"]["alpha"])
	imgui.SetNextWindowPos(imgui.ImVec2(w / 2, h / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	imgui.SetNextWindowSize(imgui.ImVec2(450, 105))
	imgui.Begin(string.format("%s##5", imgui_script_name), nil, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)
		imgui.BeginChild("##mark_and_number", imgui.ImVec2(350, 63))
			imgui.SetCursorPos(imgui.ImVec2(5, 5))
			imgui.BeginGroup() -- маркировка юнита
				imgui.CustomButton(u8"Маркировка юнита", imgui.ImVec2(120, 20))  imgui.SameLine()
				imgui.PushItemWidth(90)
				if imgui.Combo("##combo", imgui_patrol_current, imgui_patrol_list, 9) then
					t_patrol_status["mark"] = convert_patrol_list[imgui_patrol_current[0] + 1]
				end

				imgui.SameLine() -- same

				if imgui.Button(u8"Определить", imgui.ImVec2(110, 20)) then
					local mark, number = sampGetMarkCharByVehicle(playerPed)
					imgui_patrol_current[0] = number
					t_patrol_status["mark"] = mark
				end

				imgui.Hint("mark_unit", u8"Автоматически определит маркировку для вашего юнита.")
			imgui.EndGroup()

			imgui.SetCursorPosX(5)

			imgui.BeginGroup() -- номер юнита
				imgui.CustomButton(u8"Номер юнита", imgui.ImVec2(120, 20))  imgui.SameLine()
				imgui.PushItemWidth(90)
				if imgui.InputTextWithHint("##unitnumber", u8"(1 - 99)", imgui_patrol_number, 10) then
					local number = tonumber(str(imgui_patrol_number))
					if not number or number < 0 or number > 99 then imgui_patrol_number = new.char[256]() end
					t_patrol_status["number"] = number
				end

				imgui.SameLine() -- same

				if imgui.Button(u8"Сгенерировать", imgui.ImVec2(110, 20)) then
					local random = math.random(1, 100)
					imgui_patrol_number = new.char[256](tostring(random))
					t_patrol_status["number"] = random
				end
				imgui.Hint("generate_mark_unit", u8"Сгенерирует уникальный номер юнита.")
			imgui.EndGroup()
		imgui.EndChild()

		imgui.SameLine() -- same

		imgui.BeginChild("##active", imgui.ImVec2(70, 63))
			if patrol_status["status"] then
				if t_patrol_status["mark"] == patrol_status["mark"] and t_patrol_status["number"] == patrol_status["number"] then
					imgui.SetCursorPos(imgui.ImVec2(5, 5))
					if imgui.Button(faicons["ICON_TIMES_CIRCLE"], imgui.ImVec2(60, 20)) then -- окончание
						command_r("cod 13")
						mimgui_window("patrol_bar", false)
						patrol_status = {}
						return false
					end

					imgui.Hint("##finish", u8"Нажмите, чтобы завершить патрулирование.")

					imgui.SetCursorPos(imgui.ImVec2(5, 35))
					if imgui.Button(faicons["ICON_EYE_SLASH"], imgui.ImVec2(60, 20)) then -- тихое окончание
						mimgui_window("patrol_bar", false)
						patrol_status = {}
						return false
					end

					imgui.Hint("##silence_finish", u8"Нажмите, чтобы завершить патрулирование без уведомления в рацию.")
				else
					imgui.SetCursorPos(imgui.ImVec2(5, 5))
					if imgui.Button(faicons["ICON_RETWEET"], imgui.ImVec2(60, 20)) then -- обновление данных
						command_r(string.format("Говорит $m, меняю маркировку с текущей на %s-%s, доступен.", t_patrol_status["mark"], t_patrol_status["number"]))
						patrol_status = { ["status"] = 4, ["mark"] = t_patrol_status["mark"], ["number"] = t_patrol_status["number"], ["clock"] = patrol_status["clock"] }
					end

					imgui.Hint("##start", u8"Нажмите, чтобы обновить данные о патруле.")

					imgui.SetCursorPos(imgui.ImVec2(5, 35)) 
					if imgui.Button(faicons["ICON_TIMES_CIRCLE"], imgui.ImVec2(25, 20)) then -- окончание
						command_r("cod 13")
						mimgui_window("patrol_bar", false)
						patrol_status = {}
						return false
					end

					imgui.Hint("##finish", u8"Нажмите, чтобы завершить патрулирование.")

					imgui.SameLine() -- same

					if imgui.Button(faicons["ICON_EYE_SLASH"], imgui.ImVec2(25, 20)) then -- тихое окончание
						mimgui_window("patrol_bar", false)
						patrol_status = {}
						return false
					end

					imgui.Hint("##silence_finish", u8"Нажмите, чтобы завершить патрулирование без уведомления в рацию.")
				end
			else
				imgui.SetCursorPos(imgui.ImVec2(5, 5))
				if imgui.Button(faicons["ICON_TAXI"], imgui.ImVec2(60, 20)) then
					if t_patrol_status["mark"] and t_patrol_status["number"] then
						patrol_status = { ["status"] = 4, ["mark"] = t_patrol_status["mark"], ["number"] = t_patrol_status["number"], ["clock"] = os.clock() }
						mimgui_window("patrol_bar", true)
						command_r("cod 11")
						chat("Чтобы активировать курсор для взаимодействия с патрульным блоком {HEX}нажмите клавишу B{}.")
					else
						chat("Для начала необходимо указать маркировку и номер юнита.")
					end
				end

				imgui.Hint("##start", u8"Нажмите, чтобы начать патрулирование.")

				imgui.SetCursorPos(imgui.ImVec2(5, 35))
				if imgui.Button(faicons["ICON_EYE_SLASH"], imgui.ImVec2(60, 20)) then -- тихое начало
					if t_patrol_status["mark"] and t_patrol_status["number"] then
						patrol_status = { ["status"] = 4, ["mark"] = t_patrol_status["mark"], ["number"] = t_patrol_status["number"], ["clock"] = os.clock() }
						mimgui_window("patrol_bar", true)
						chat("Чтобы активировать курсор для взаимодействия с патрульным блоком {HEX}нажмите клавишу B{}.")
					else
						chat("Для начала необходимо указать маркировку и номер юнита.")
					end
				end

				imgui.Hint("##silence_start", u8"Нажмите, чтобы начать патрулирование без уведомления в рацию.")
			end
		imgui.EndChild()
	imgui.End()
	imgui.PopStyleVar()
end)

imgui.OnFrame(function() return t_mimgui_render["editor_quick_suspect"]["alpha"] > 0.0 end,
function(self)
	if not time_quick_suspect then t_mimgui_render["editor_quick_suspect"]["switch"]() end

	self["HideCursor"] = not t_mimgui_render["editor_quick_suspect"]["state"]
	imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, t_mimgui_render["editor_quick_suspect"]["alpha"])
	imgui.SetNextWindowPos(imgui.ImVec2(w / 2, h / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	imgui.SetNextWindowSize(imgui.ImVec2(300, 208))
	imgui.Begin(string.format("%s##editor_npa", imgui_script_name), nil, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)
		imgui.BeginChild("##selected_value", imgui.ImVec2(280, 30))
			imgui.SetCursorPos(imgui.ImVec2(5, 5)) -- fix
			imgui.CustomButton(string.format(u8"%s, %sй уровень розыска.", time_quick_suspect["reason"], time_quick_suspect["stars"]), imgui.ImVec2(270, 20))
		imgui.EndChild()

		imgui.BeginChild("##value", imgui.ImVec2(280, 130))
			imgui.SetCursorPosY(5) -- fix Y
			for index, value in ipairs(t_quick_suspect) do
				imgui.SetCursorPosX(5) -- fix X
				if imgui.Button(value["description"], imgui.ImVec2(270, 20)) then
					local index = string.gsub(value["index"], "##", "")
					configuration["MAIN"]["quick_criminal_code"][index] = {  
						["stars"] = time_quick_suspect["stars"],
						["reason"] = time_quick_suspect["reason"]
					}

					chat(string.format("Для преступления \"{HEX}%s{}\" будет инкриминироваться {HEX}%s{}, {HEX}%s{} уровень розыска.", string.nlower(u8:decode(value["description"])), u8:decode(time_quick_suspect["reason"]), time_quick_suspect["stars"]))

					time_quick_suspect = false
					mimgui_window("editor_quick_suspect", false)

					if not need_update_configuration then need_update_configuration = os.clock() end
				end
			end
			imgui.EndChild()
	imgui.End()
	imgui.PopStyleVar()
end)

imgui.OnFrame(function() return t_mimgui_render["regulatory_legal_act"]["alpha"] > 0.0 end, -- нормативно-правовые акты в прайм-тайм
function(self)
	if not viewing_documents then
		if smart_suspect_id and not isPlayerConnected(smart_suspect_id) then
			mimgui_window("regulatory_legal_act", false)
			chat("Подозреваемый покинул игру.")
			return
		end
	end

	local document = global_current_document

	self["HideCursor"] = not t_mimgui_render["regulatory_legal_act"]["state"]

	-- imgui.CaptureMouseFromApp(true)
	imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, t_mimgui_render["regulatory_legal_act"]["alpha"])
	imgui.SetNextWindowPos(imgui.ImVec2(w / 2, h / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	imgui.SetNextWindowSize(imgui.ImVec2(570, 600))

	imgui.Begin(string.format("%s##npa", imgui_script_name), nil, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)
		imgui.PushItemWidth(545)
		if imgui.InputTextWithHint("##regulatory_legal_act_i", u8"Введите часть содержания статьи", string_found[1], ffi.sizeof(string_found[1]) - 1, imgui.InputTextFlags.CallbackHistory + imgui.InputTextFlags.CallbackCompletion) then	
			local pattern = string.nlower(u8:decode(str(string_found[1])))
			for article, value in ipairs(document["content"]) do
				document["content"][article]["visible"] = true

				local article_pattern = string.nlower(u8:decode(value["title"]))
				if string.match(article_pattern, pattern) then document["content"][article]["visible"] = false end

				local part_found = 0
				for part, pvalue in ipairs(value["content"]) do
					document["content"][article]["content"][part]["visible"] = true

					local part_pattern = string.nlower(u8:decode(pvalue["title"]))
					if string.match(part_pattern, pattern) then
						part_found = part_found + 1
						document["content"][article]["visible"] = false
						document["content"][article]["content"][part]["visible"] = false
					end
				end

				if not document["content"][article]["visible"] and part_found == 0 then
					for part, pvalue in ipairs(value["content"]) do
						document["content"][article]["content"][part]["visible"] = false
					end
				end
			end
		end

		for article, value in ipairs(document["content"]) do
			if not value["visible"] then
				if imgui.TreeNodeStr(value["treenode_article"]) then
					for part, lvalue in ipairs(value["content"]) do
						if not lvalue["visible"] then
							if imgui.Button(string.format("%s##b-%s-%s", button_punishment[lvalue["type_punishment"]], article, part)) then
								if not viewing_documents then
									if lvalue["type_punishment"] == 1 then
										command_ticket(string.format("%s %s %s.%s КоАП", smart_suspect_id, lvalue["value_punishment"], article, part))
									elseif lvalue["type_punishment"] == 2 then
										command_takelic(string.format("%s %s.%s КоАП", smart_suspect_id, article, part))
									elseif lvalue["type_punishment"] == 3 then
										command_su(string.format("%s %s %s.%s УК", smart_suspect_id, lvalue["value_punishment"], article, part))
									end
								else
									if lvalue["type_punishment"] == 3 then
										time_quick_suspect = { ["stars"] = lvalue["value_punishment"], ["reason"] = string.format(u8"%s.%s УК", article, part) }
										mimgui_window("editor_quick_suspect", true)
									end
								end
							end imgui.SameLine()

							if imgui.CustomButton(lvalue["treenode_part"]) then
								if not viewing_documents then
									if lvalue["type_punishment"] == 1 then
										command_ticket(string.format("%s %s %s.%s КоАП", smart_suspect_id, lvalue["value_punishment"], article, part))
									elseif lvalue["type_punishment"] == 2 then
										command_takelic(string.format("%s %s.%s КоАП", smart_suspect_id, article, part))
									elseif lvalue["type_punishment"] == 3 then
										command_su(string.format("%s %s %s.%s УК", smart_suspect_id, lvalue["value_punishment"], article, part))
									end
								else
									if lvalue["type_punishment"] == 3 then
										time_quick_suspect = { ["stars"] = lvalue["value_punishment"], ["reason"] = string.format(u8"%s.%s УК", article, part) }
										mimgui_window("editor_quick_suspect", true)
									end
								end
							end
							imgui.Hint(lvalue["hint_index"], lvalue["hint_value"])
						end
					end
					imgui.TreePop()
				end
			end
		end
	imgui.End()
	imgui.PopStyleVar()
end)

imgui.OnFrame(function() return t_mimgui_render["tags_information"]["alpha"] > 0.0 end,
function(self)
	self["HideCursor"] = not t_mimgui_render["tags_information"]["state"]
	imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, t_mimgui_render["tags_information"]["alpha"])
	imgui.SetNextWindowPos(imgui.ImVec2(w / 2, h / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	imgui.SetNextWindowSize(imgui.ImVec2(480, 300))
	imgui.Begin(string.format("%s##12", imgui_script_name), nil, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)
		imgui.BeginChild("##tags_information", imgui.ImVec2(460, 259))
			imgui.SetCursorPosY(5) -- fix Y
			for index, value in ipairs(t_tags_and_functions) do
				imgui.CustomButton(string.format("%s##tags_information", index), imgui.ImVec2(25, 20)) -- tags id
				imgui.SameLine() -- same

				if imgui.Button(value["index"], imgui.ImVec2(100, 20)) then -- отображение тэга или функции
					setClipboardText(value["index"])
				end
				imgui.SameLine() -- same

				imgui.CustomButton(value["description"]) -- описание тэга или функции
			end
		imgui.EndChild()
	imgui.End()
	imgui.PopStyleVar()
end)

imgui.OnFrame(function() return t_mimgui_render["main_menu"]["alpha"] > 0.00 end, -- основное меню
function(self)
    self.HideCursor = not t_mimgui_render["main_menu"]["state"]
    imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, t_mimgui_render["main_menu"]["alpha"])

	imgui.SetNextWindowPos(imgui.ImVec2(w / 2, h / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	imgui.SetNextWindowSize(imgui.ImVec2(650, 435))
	imgui.Begin(string.format("%s##1", imgui_script_name), nil, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)

		imgui.SetCursorPosX(96) -- fix X

		imgui.BeginGroup()
			for index, title in ipairs(main_menu_navigation["list"]) do
				if header_button(main_menu_navigation["current"] == index, title) then main_menu_navigation["current"] = index end
				if index ~= #main_menu_navigation["list"] then imgui.SameLine(nil, 30) end
			end
		imgui.EndGroup()

		imgui.NewLine() -- new line

		if main_menu_navigation["current"] == 1 then
			if not update_log[1][3] then
				for index, version in ipairs(update_log) do
					local maximum_size = 0
					for k, value in ipairs(version[2]) do
						local value = tostring(value)
						if maximum_size < imgui.CalcTextSize(value).x then maximum_size = imgui.CalcTextSize(value).x end
					end
					update_log[index][3], update_log[index][4] = (maximum_size + 10), (18 * #version[2] + 83)
				end
			end

			for index, value in ipairs(update_log) do
				imgui.SetCursorPosX(50)
				imgui.BeginChild(string.format("##update_log-%s", index), imgui.ImVec2(550, value[4]))

					imgui.SetCursorPos(imgui.ImVec2(10, 10))

					imgui.BeginGroup()
						imgui.Button(faicons["ICON_GITHUB_ALT"], imgui.ImVec2(30, 30))
					imgui.EndGroup()

					imgui.SameLine() -- same

					imgui.SetCursorPosY(6)
					imgui.BeginGroup()
						imgui.Text(value[1])
						imgui.TextDisabled(value["date"])
					imgui.EndGroup()

					imgui.SetCursorPosY(50)

					for index, value in ipairs(value[2]) do 
						imgui.SetCursorPosX(10)
						imgui.Text(value) 
					end

					imgui.SetCursorPos(imgui.ImVec2(10, value[4] - 30))

					if not configuration["MAIN"]["update_stars"][index] then
						if imgui.CustomButton(string.format(u8"%s##like-%s", faicons["ICON_HEART_O"], index), imgui.ImVec2(23, 23), 0) then
							current_update_scores = index
							t_mimgui_render["update_scores"]["switch"]()
						end
						imgui.SameLine(nil, 3)
						imgui.TextDisabled(u8"Вы ещё не оценили это обновление :с")
					else
						imgui.CustomButton(string.format(u8"%s##like-%s", faicons["ICON_HEART"], index), imgui.ImVec2(23, 23), 0)
						imgui.SameLine(nil, 3)
						imgui.TextDisabled(string.format(u8"Ваша оценка: %s", configuration["MAIN"]["update_stars"][index]))
					end
				imgui.EndChild()

				imgui.NewLine() -- new line
			end

			imgui.CenterText(u8"Helper for MIA © 2019-2022")
		elseif main_menu_navigation["current"] == 2 then
			imgui.BeginGroup()
				imgui.BeginChild("##navigation", imgui.ImVec2(220, 41))
					imgui.SetCursorPos(imgui.ImVec2(62, 15))
					for index = 1, 5 do
						if im_circle_button("##nav-" .. index, (index == settings_menu_navigation["current"])) then
							settings_menu_navigation["current"] = index
						end if index ~= 5 then imgui.SameLine() end
					end
				imgui.EndChild()

				imgui.SameLine() -- same

				imgui.BeginChild("##plus_and_serial", imgui.ImVec2(400, 41))
					imgui.SetCursorPos(imgui.ImVec2(10, 10))
					if imgui.CustomButton(string.format("#%s", player_serial_number)) then
						setClipboardText(tostring(player_serial_number))
					end
					imgui.Hint("serial_copy", u8"Нажмите, чтобы скопировать серийный номер этого аккаунта.")

					imgui.SameLine(205) -- same

					if imgui.CustomButton(u8"Перезагрузить") then
						is_script_exit = true
						thisScript():reload()
					end imgui.SameLine() -- same

					if imgui.CustomButton(u8"Выключить") then
						is_script_exit = true
						thisScript():unload() 
					end
				imgui.EndChild()
			imgui.EndGroup()

			if settings_menu_navigation["current"] == 1 then
				imgui.SetCursorPosY(118) -- fix Y
				imgui.BeginChild("##information_about_user", imgui.ImVec2(165, 175))
					imgui.PushItemWidth(150)
					imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(0.0, 0.0, 0.0, 0.0))

					for index, value in ipairs(t_input_user_information) do
						imgui.SetCursorPos(imgui.ImVec2(5, 5 + 28 * (index - 1)))
						im_input_with_hint(value["index"], value["hint"], value["value"], 50, value["path"])
					end

					imgui.PopStyleColor(1)
				imgui.EndChild()

				imgui.SameLine() -- same

				imgui.BeginChild("##improved_dialogs", imgui.ImVec2(260, 175))
					for index, value in ipairs(t_improved_dialogs) do
						imgui.SetCursorPos(imgui.ImVec2(5, (9 + 23 * (index - 1))))
						im_toggle_button(value["index"], value["description"], value["path"])
					end
				imgui.EndChild()

				imgui.SameLine() -- same

				imgui.BeginChild("##automatic_receipt_weapons", imgui.ImVec2(185, 260))
					for index, value in ipairs(t_automatic_receipt_weapons) do
						imgui.SetCursorPos(imgui.ImVec2(5, (9 + 23 * (index - 1))))
						im_toggle_button(value["index"], value["description"], value["path"])
					end
				imgui.EndChild()

				imgui.SetCursorPosY(303) -- fix Y
				imgui.BeginChild("##basic_settings", imgui.ImVec2(435, 121))
					for index, value in ipairs(t_basic_settings) do
						imgui.SetCursorPos(imgui.ImVec2(5, (6 + 23 * (index - 1))))
						im_toggle_button(value["index"], value["description"], value["path"])
					end
				imgui.EndChild()

				imgui.SameLine() -- same

				imgui.BeginGroup()
					imgui.SetCursorPosY(390) -- fix Y
					imgui.BeginChild("##helperformia", imgui.ImVec2(185, 33))
						imgui.SetCursorPos(imgui.ImVec2(9, 6))
						if imgui.Button(u8"Helper for MIA © 2019-2022") then
							--
						end
					imgui.EndChild()
				imgui.EndGroup()
			elseif settings_menu_navigation["current"] == 2 then
				imgui.BeginGroup()
					imgui.SetCursorPosY(118) -- fix Y
					imgui.BeginChild("##t_player_renders", imgui.ImVec2(295, 80))
						for index, value in ipairs(t_player_renders) do
							imgui.SetCursorPos(imgui.ImVec2(5, (6 + 23 * (index - 1))))
							im_toggle_button(value["index"], value["description"], value["path"])
						end

						imgui.SetCursorPosX(7) -- fix X
						imgui.PushItemWidth(280)
						im_slider_int("##rkdelay", 1, 30, { "MAIN", "settings", "delay_between_deaths" })
						imgui.Hint("##hrkdelay", u8"Время, в течение которого нельзя возвращаться на место смерти (RK).")
					imgui.EndChild()

					imgui.SetCursorPosY(207) -- fix Y
					imgui.BeginChild("##t_transport_improvements", imgui.ImVec2(295, 77))
						for index, value in ipairs(t_transport_improvements) do
							imgui.SetCursorPos(imgui.ImVec2(5, (6 + 23 * (index - 1))))
							im_toggle_button(value["index"], value["description"], value["path"])
						end
					imgui.EndChild()

					imgui.SetCursorPosY(294) -- fix Y
					imgui.BeginChild("##t_quick_suspect", imgui.ImVec2(295, 130))
						imgui.SetCursorPos(imgui.ImVec2(5, 5))
						if imgui.Button(u8"##местоположение", imgui.ImVec2(285, 5)) then
							lua_thread.create(function()
								chat("При помощи курсора {HEX}перенесите интерфейс{} на удобное Вам место, а затем {HEX}нажмите ЛКМ для сохранения{}.")
								local result, player_id = sampGetPlayerIdByCharHandle(playerPed)
								preliminary_check_suspect(player_id, 1, true, false)

								while true do wait(0)
									if sampGetCursorMode() ~= 3 then sampSetCursorMode(3) end
									configuration["MAIN"]["settings"]["tq_interface_x"], configuration["MAIN"]["settings"]["tq_interface_y"] = getCursorPos()
									if wasKeyPressed(vkeys.VK_LBUTTON) then sampSetCursorMode(0) break end
								end sampSetCursorMode(0)

								chat("Все изменения были сохранены.")
								if not need_update_configuration then need_update_configuration = os.clock() end
							end)
						end

						imgui.Hint("##hместоположение", u8"Нажмите, чтобы изменить местоположение интерфейса быстрого розыска.")

						for index, value in ipairs(t_quick_suspect) do
							imgui.SetCursorPos(imgui.ImVec2(5, -8 + 23 * index))
							im_toggle_button(value["index"], value["description"], value["path"])
						end
					imgui.EndChild()
				imgui.EndGroup()

				imgui.SameLine() -- same

				imgui.BeginGroup()
					imgui.SetCursorPosY(118) -- fix Y
					imgui.BeginChild("##t_chat_and_enter", imgui.ImVec2(325, 125))
						for index, value in ipairs(t_chat_and_enter) do
							imgui.SetCursorPos(imgui.ImVec2(5, (6 + 23 * (index - 1))))
							im_toggle_button(value["index"], value["description"], value["path"])
						end
					imgui.EndChild()

					imgui.SetCursorPosY(253) -- fix Y
					imgui.BeginChild("##t_automatics_actions", imgui.ImVec2(325, 123))
						for index, value in ipairs(t_automatics_actions) do
							imgui.SetCursorPos(imgui.ImVec2(5, (6 + 23 * (index - 1))))
							im_toggle_button(value["index"], value["description"], value["path"])
						end
					imgui.EndChild()
				imgui.EndGroup()
			elseif settings_menu_navigation["current"] == 3 then
				imgui.SetCursorPosY(118) -- fix Y
				imgui.BeginChild("##upper", imgui.ImVec2(630, 55))
					imgui.SetCursorPos(imgui.ImVec2(5, 5))
					imgui.Button(string.format(u8"Оружие, выбранное для редактирования: %s (%s)", t_role_play_weapons[im_weapons_selected]["description"], im_weapons_selected), imgui.ImVec2(380, 20))
					imgui.SameLine() -- same
					imgui.PushItemWidth(230)
					im_slider_float("##weapons_delay", 0.0, 2.0, { "MAIN", "settings", "waiting_time_taking_weapons" })
					imgui.Hint("##hweapons_delay", u8"Время, в течение которого оружие должно находится в руках, чтобы сработала отыгровка.")
					im_toggle_button("##automatic_weapon_acting_out", u8"Выполнять отыгровку автоматически по истечение указанного времени, в ином случае нажатием ПКМ", { "MAIN", "settings", "auto_weapon_acting_out" })
				imgui.EndChild()

				imgui.SetCursorPosY(182) -- fix Y

				imgui.BeginChild("##medium", imgui.ImVec2(630, 58))
					imgui.PushItemWidth(620)
					imgui.SetCursorPos(imgui.ImVec2(5, 5))
					if imgui.InputTextWithHint("##role_play_action_take", u8"Отыгровка в момент взятия оружия в руки", im_role_play_action_weapon_take, 150) then
						local index = t_role_play_weapons[im_weapons_selected]["index"]
						configuration["MAIN"]["role_play_weapons"][index]["take"] = str(im_role_play_action_weapon_take)
						if not need_update_configuration then need_update_configuration = os.clock() end
					end

					imgui.SetCursorPosX(5) -- fix X
					if imgui.InputTextWithHint("##role_play_action_remove", u8"Отыгровка в момент скрытия оружия из рук", im_role_play_action_weapon_remove, 150) then
						local index = t_role_play_weapons[im_weapons_selected]["index"]
						configuration["MAIN"]["role_play_weapons"][index]["remove"] = str(im_role_play_action_weapon_remove)
						if not need_update_configuration then need_update_configuration = os.clock() end
					end
				imgui.EndChild()

				imgui.SetCursorPosY(250) -- fix Y
				imgui.BeginChild("##lower", imgui.ImVec2(630, 175))
					imgui.SetCursorPos(imgui.ImVec2(5, 10))
					for index, value in ipairs(t_role_play_weapons) do
						if value then
							local button_hovered = (im_weapons_selected == index)
							if button_hovered then
								if imgui.CustomButton(value["description"]) then
									im_weapons_selected = index
									local index = t_role_play_weapons[im_weapons_selected]["index"]
									im_role_play_action_weapon_take = new.char[516](configuration["MAIN"]["role_play_weapons"][index]["take"])
									im_role_play_action_weapon_remove = new.char[516](configuration["MAIN"]["role_play_weapons"][index]["remove"])
								end
							else
								if imgui.Button(value["description"]) then
									im_weapons_selected = index
									local index = t_role_play_weapons[im_weapons_selected]["index"]
									im_role_play_action_weapon_take = new.char[516](configuration["MAIN"]["role_play_weapons"][index]["take"])
									im_role_play_action_weapon_remove = new.char[516](configuration["MAIN"]["role_play_weapons"][index]["remove"])
								end
							end

							if math.fmod(index, 8) ~= 0 then imgui.SameLine() else imgui.SetCursorPosX(5) end
						end
					end
					imgui.TreePop()
				imgui.EndChild()
			elseif settings_menu_navigation["current"] == 4 then
				imgui.PushItemWidth(240)
				imgui.SetCursorPosY(118) -- fix Y
				if imgui.ColorPicker3("##customization", im_float_color) then
					im_update_color()
				end

				imgui.SameLine() -- same

				imgui.BeginChild("##information_about_customization", imgui.ImVec2(313, 305))
					imgui.SetCursorPos(imgui.ImVec2(5, 8))
					if im_toggle_button("##customization", u8"Кастомизация интерфейсов", { "MAIN", "settings", "customization" }) then
						apply_custom_style()
					end

					imgui.BeginGroup() -- red
						imgui.SetCursorPos(imgui.ImVec2(6, 50))
						if imgui.CustomButton("Indian Red", imgui.ImVec2(155, 25), imgui.ImVec4(0.8, 0.36, 0.36, 1.0)) then
							im_float_color = new.float[3](0.8, 0.36, 0.36)
							im_update_color()
						end imgui.SameLine() -- same

						if imgui.CustomButton("Crimson", imgui.ImVec2(135, 25), imgui.ImVec4(0.86, 0.08, 0.24, 1.0)) then
							im_float_color = new.float[3](0.86, 0.08, 0.24)
							im_update_color()
						end

						imgui.SetCursorPos(imgui.ImVec2(6, 85))
						if imgui.CustomButton("Light Coral", imgui.ImVec2(135, 25), imgui.ImVec4(0.94, 0.5, 0.5, 1.0)) then
							im_float_color = new.float[3](0.94, 0.5, 0.5)
							im_update_color()
						end imgui.SameLine() -- same

						if imgui.CustomButton("Fire Brick", imgui.ImVec2(155, 25), imgui.ImVec4(0.7, 0.13, 0.13, 1.0)) then
							im_float_color = new.float[3](0.7, 0.13, 0.13)
							im_update_color()
						end
					imgui.EndGroup()

					imgui.BeginGroup() -- green
						imgui.SetCursorPos(imgui.ImVec2(6, 133))
						if imgui.CustomButton("Sea Green", imgui.ImVec2(135, 25), imgui.ImVec4(0.18, 0.55, 0.34, 1.0)) then
							im_float_color = new.float[3](0.18, 0.55, 0.34)
							im_update_color()
						end imgui.SameLine() -- same

						if imgui.CustomButton("Dark Cyan", imgui.ImVec2(155, 25), imgui.ImVec4(0.0, 0.55, 0.55, 1.0)) then
							im_float_color = new.float[3](0.0, 0.55, 0.55)
							im_update_color()
						end

						imgui.SetCursorPos(imgui.ImVec2(6, 168))
						if imgui.CustomButton("Light Green", imgui.ImVec2(155, 25), imgui.ImVec4(0.24, 0.48, 0.28, 1.0)) then
							im_float_color = new.float[3](0.24, 0.48, 0.28)
							im_update_color()
						end imgui.SameLine() -- same

						if imgui.CustomButton("Dark Sea Green", imgui.ImVec2(135, 25), imgui.ImVec4(0.56, 0.74, 0.55, 1.0)) then
							im_float_color = new.float[3](0.56, 0.74, 0.55)
							im_update_color()
						end
					imgui.EndGroup()

					imgui.BeginGroup() -- blue
						imgui.SetCursorPos(imgui.ImVec2(6, 216))
						if imgui.CustomButton("Steel Blue", imgui.ImVec2(155, 25), imgui.ImVec4(0.27, 0.51, 0.71, 1.0)) then
							im_float_color = new.float[3](0.27, 0.51, 0.71)
							im_update_color()
						end imgui.SameLine() -- same

						if imgui.CustomButton("Powder Blue", imgui.ImVec2(135, 25), imgui.ImVec4(0.69, 0.88, 0.9, 1.0)) then
							im_float_color = new.float[3](0.69, 0.88, 0.9)
							im_update_color()
						end

						imgui.SetCursorPos(imgui.ImVec2(6, 250))
						if imgui.CustomButton("Medium Slate Blue", imgui.ImVec2(135, 25), imgui.ImVec4(0.48, 0.41, 0.93, 1.0)) then
							im_float_color = new.float[3](0.48, 0.41, 0.93)
							im_update_color()
						end imgui.SameLine() -- same

						if imgui.CustomButton("Turquoise", imgui.ImVec2(155, 25), imgui.ImVec4(0.25, 0.88, 0.82, 1.0)) then
							im_float_color = new.float[3](0.25, 0.88, 0.82)
							im_update_color()
						end
					imgui.EndGroup()
				imgui.EndChild()
			elseif settings_menu_navigation["current"] == 5 then
				imgui.SetCursorPosY(118) -- fix Y

				imgui.BeginChild("##limit_characters", imgui.ImVec2(303, 240))
					imgui.SetCursorPos(imgui.ImVec2(5, 5)) -- fix X
					imgui.PushItemWidth(150)

					for index, value in ipairs(t_limit_characters) do
						imgui.SetCursorPosX(5) -- fix X
						im_slider_int(value["index"], 50, 90, value["path"])

						imgui.SameLine() -- same
						imgui.Button(value["description2"], imgui.ImVec2(35, 20))

						imgui.SameLine() -- same
						imgui.CustomButton(value["description1"])
					end
				imgui.EndChild()

				imgui.SameLine()

				imgui.BeginChild("##block_for_block", imgui.ImVec2(315, 305))
					imgui.SetCursorPosY(115) -- fix Y
					imgui.CenterText(u8"это пустой блок")
					imgui.CenterText(u8"он когда-нибудь заполнится")
					imgui.CenterText(u8"наверное :l")
				imgui.EndChild()
			end
		elseif main_menu_navigation["current"] == 3 then
			imgui.PushItemWidth(630)
			if imgui.InputTextWithHint("##data_base_input", u8"Введите никнейм, номер дома или часть любой другой информации, что желаете найти", string_found[2], 50) then
				t_database_search = {
					{ ["index"] = u8"Игроки", ["matches"] = 0, ["content"] = {} },
					{ ["index"] = u8"Недвижимость", ["matches"] = 0, ["content"] = {} }
				}

				for index, value in pairs(configuration["DATABASE"]["player"]) do
					if type(value) == "table" then
						local is_match
						for lindex, lvalue in pairs(value) do
							if type(lvalue) ~= "table" then
								local input = string.nlower(tostring(lvalue))
								local pattern = string.nlower(str(string_found[2]))
								if string.match(input, pattern) or string.match(string.nlower(index), pattern) then
									t_database_search[1]["content"][index] = value
									is_match = true
								end
							end
						end if is_match then t_database_search[1]["matches"] = t_database_search[1]["matches"] + 1 end
					end
				end

				for index, value in pairs(configuration["DATABASE"]["house"]) do
					if type(value) == "table" then
						local is_match
						for lindex, lvalue in pairs(value) do
							if type(lvalue) ~= "table" then
								local input = string.nlower(tostring(lvalue))
								local pattern = string.nlower(str(string_found[2]))
								if string.match(input, pattern) or string.match(string.nlower(index), pattern) then
									t_database_search[2]["content"][index] = value
									is_match = true
								end
							end
						end if is_match then t_database_search[2]["matches"] = t_database_search[2]["matches"] + 1 end
					end
				end
			end

			for index, value in ipairs(t_database_search) do
				if imgui.TreeNodeStr(string.format("%s (%s)", value["index"], value["matches"])) then
					for lindex, lvalue in pairs(value["content"]) do
						if imgui.TreeNodeStr(tostring(lindex)) then
							displaying_inline_sections(lvalue)
							imgui.TreePop()
						end
					end
					imgui.TreePop()
				end
			end
		elseif main_menu_navigation["current"] == 4 then
			if binder_menu_navigation["current"] == 4 then
				imgui.BeginChild("##navigation", imgui.ImVec2(630, 41))
					imgui.SetCursorPos(imgui.ImVec2(10, 10))
					imgui.CustomButton(string.format("ID: %s", binder_menu_navigation["content"]["index"]))
					imgui.SameLine()

					if binder_menu_navigation["content"]["system"] then
						imgui.Button(string.format("/%s", binder_menu_navigation["content"]["command"]), imgui.ImVec2(120, 20))
					else
						imgui.PushItemWidth(118)
						imgui.InputTextWithHint("##input_command", u8"/команда", im_input_command, 20)
						imgui.Hint("##input_command", u8"Введите желаемое название для команды.\nУказывать / перед командой не нужно.")
					end

					imgui.SameLine() -- same

					if imgui.CustomButton(faicons["ICON_FILE_TEXT"], imgui.ImVec2(20, 20)) then -- save
						local path = binder_menu_navigation["content"]["path"]

						if not binder_menu_navigation["content"]["system"] then
							local command = str(im_input_command)
							if string.match(u8:decode(command), "[а-яА-Я0-9]") then
								chat("Название команды должно содержать исключительно латинские символы.")
								return
							end

							if command ~= binder_menu_navigation["content"]["command"] and sampIsChatCommandDefined(command) then
								chat("Команда с таким названием уже зарегистрирована.")
								return
							end

							configuration["CUSTOM"][path[1]][path[2]][path[3]]["command"] = command
							binder_menu_navigation["content"]["command"] = command
						end

						local content = str(binder_menu_navigation["content"]["content"])
						local result = {}

						for value in string.gmatch(content, "[^\n]+") do table.insert(result, value) end -- конвертируем текст в таблицу

						local variations = binder_menu_navigation["content"]["variations"]
						configuration["CUSTOM"][path[1]][path[2]][path[3]]["variations"][variations] = result

						configuration["CUSTOM"][path[1]][path[2]][path[3]]["parametrs_amount"] = im_input_parametrs[0]

						chat(string.format("Все изменения для команды {HEX}%s{} (#{HEX}%s{}) были успешно сохранены.", string.upper(binder_menu_navigation["content"]["command"]), variations))

						if not need_update_configuration then need_update_configuration = os.clock() end
					end

					imgui.Hint("##save", u8"Нажмите, чтобы сохранить внесённые изменения.")
					imgui.SameLine() -- same

					if imgui.CustomButton(faicons["ICON_TRASH"], imgui.ImVec2(20, 20)) then -- delete
						if binder_menu_navigation["content"]["system"] then
							chat("Нельзя удалить системную команду.")
						else
							local path = binder_menu_navigation["content"]["path"]

							if configuration["CUSTOM"][path[1]][path[2]][path[3]]["keys"] then
								if configuration["CUSTOM"][path[1]][path[2]][path[3]]["keys"]["v"] then
									local result, id = rkeys.isHotKeyDefined(configuration["CUSTOM"][path[1]][path[2]][path[3]]["keys"]["v"])
									if result then rkeys.unRegisterHotKey(id) end
								end
							end

							sampUnregisterChatCommand(binder_menu_navigation["content"]["command"])

							chat(string.format("Вы удалили пользовательскую команду {HEX}%s{} #{HEX}%s{}", string.upper(binder_menu_navigation["content"]["command"]), binder_menu_navigation["content"]["index"]))
							table.remove(configuration["CUSTOM"]["USERS"]["main"], binder_menu_navigation["content"]["index"])
							binder_menu_navigation["current"] = 2

							if not need_update_configuration then need_update_configuration = os.clock() end

							return
						end
					end

					imgui.Hint("##delete", u8"Нажмите, чтобы безвозвратно удалить эту команду.")
					imgui.SameLine() -- same

					if imgui.CustomButton(faicons["ICON_FILE_O"], imgui.ImVec2(20, 20)) then -- clear
						binder_menu_navigation["content"]["content"] = new.char[9999]()
					end

					imgui.Hint("##clear", u8"Нажмите, чтобы очистить поле редактирования от текста.")
					imgui.SameLine() -- same

					if imgui.CustomButton(faicons["ICON_TAG"], imgui.ImVec2(20, 20)) then -- tags
						mimgui_window("tags_information")
					end

					imgui.Hint("##tags", u8"Нажмите, чтобы открыть список вспомогательных тэгов.")
					imgui.SameLine() -- same

					imgui.SetCursorPosX(570)

					if imgui.CustomButton(faicons["ICON_ELLIPSIS_H"], imgui.ImVec2(20, 20)) then -- another
						binder_menu_navigation["another"] = not binder_menu_navigation["another"]
					end

					imgui.Hint("##another", u8"Нажмите, чтобы открыть дополнительные настройки команды.")
					imgui.SameLine() -- same

					if imgui.CustomButton(faicons["ICON_TIMES_CIRCLE"], imgui.ImVec2(20, 20)) then -- back
						if binder_menu_navigation["content"]["system"] then
							if binder_menu_navigation["content"]["system"] == 1 then
								binder_menu_navigation["current"] = 1
							else
								binder_menu_navigation["current"] = 2
							end
						else
							binder_menu_navigation["current"] = 2
						end
					end

					imgui.Hint("##back", u8"Нажмите, чтобы закрыть этот редактор и вернуться к списку.")
				imgui.EndChild()

				imgui.SetCursorPosY(118) -- fix Y

				if not binder_menu_navigation["another"] then
					imgui.BeginChild("##lower", imgui.ImVec2(630, 305))
						imgui.SetCursorPos(imgui.ImVec2(5, 5))
						imgui.InputTextMultiline("##input_command_content", binder_menu_navigation["content"]["content"], 9999, imgui.ImVec2(620, 295))
					imgui.EndChild()
				else
					imgui.BeginChild("##lower", imgui.ImVec2(425, 305))
						imgui.SetCursorPos(imgui.ImVec2(5, 5))
						imgui.InputTextMultiline("##input_command_content", binder_menu_navigation["content"]["content"], 9999, imgui.ImVec2(415, 295))
					imgui.EndChild()

					imgui.SameLine() -- same

					imgui.BeginChild("##variations", imgui.ImVec2(195, 305)) -- настройки и выбор вариации отыгровки команды
						for index = 1, #binder_menu_navigation["content"]["settings"]["variations"] do
							imgui.SetCursorPos(imgui.ImVec2(5, (6 + 23 * (index - 1))))
							if imgui.CustomButton(string.format(u8"Вариация выполнения #%s", index), imgui.ImVec2(155, 20)) then
								binder_menu_navigation["content"]["variations"] = index
								binder_menu_navigation["content"]["content"] = new.char[9999](table.concat(binder_menu_navigation["content"]["settings"]["variations"][index], "\n"))
								if not binder_menu_navigation["content"]["system"] then
									im_input_parametrs[0] = binder_menu_navigation["content"]["settings"]["parametrs_amount"]
								end
							end

							imgui.SameLine() -- same

							if imgui.Button(string.format("%s##destroy-%s", faicons["ICON_TRASH"], index), imgui.ImVec2(20, 20)) then
								local path = binder_menu_navigation["content"]["path"]
								if #configuration["CUSTOM"][path[1]][path[2]][path[3]]["variations"] > 1 then
									table.remove(configuration["CUSTOM"][path[1]][path[2]][path[3]]["variations"], index)
									if not need_update_configuration then need_update_configuration = os.clock() end
									return
								end
							end
						end

						imgui.SetCursorPosX(5) -- fix X

						if imgui.Button(u8"Добавить новую вариацию", imgui.ImVec2(185, 20)) then
							local path = binder_menu_navigation["content"]["path"]
							table.insert(configuration["CUSTOM"][path[1]][path[2]][path[3]]["variations"], {})
						end

						if not binder_menu_navigation["content"]["system"] then
							imgui.NewLine()

							imgui.SetCursorPosX(5) -- fix X
							imgui.Text(u8"Количество параметров:")

							imgui.SetCursorPosX(5) -- fix X
							imgui.PushItemWidth(185)
							if imgui.InputInt("##parametrs", im_input_parametrs, 1) then
								if im_input_parametrs[0] > 3 then
									im_input_parametrs[0] = 3
								elseif im_input_parametrs[0] < 0 then
									im_input_parametrs[0] = 0
								end
							end
							imgui.Hint("##input_parametrs", u8"Количество вводимых параметров для команды.\nС ними можно взаимодействовать в редакторе при помощи символов {N}, где N - число от 1 до 3х.")

							imgui.SetCursorPosX(5) -- fix X
							imgui.Text(u8"Горячие клавиши:")

							imgui.SetCursorPosX(5) -- fix X
							if not binder_menu_navigation["content"]["settings"]["keys"] then
								if imgui.Button(u8"Активация клавишами", imgui.ImVec2(185, 20)) then
									local path = binder_menu_navigation["content"]["path"]
									configuration["CUSTOM"][path[1]][path[2]][path[3]]["keys"] = { ["v"] = {} }
								end

								imgui.Hint("##add_hotkey", u8"Нажмите, чтобы добавить активацию этой команды сочетанием клавиш.")
							else
								local path = binder_menu_navigation["content"]["path"]
								if imgui.HotKey("##hotkeys", configuration["CUSTOM"][path[1]][path[2]][path[3]]["keys"], 155) then
									if not rkeys.isHotKeyDefined(configuration["CUSTOM"][path[1]][path[2]][path[3]]["keys"]["v"]) then
										rkeys.registerHotKey(configuration["CUSTOM"][path[1]][path[2]][path[3]]["keys"]["v"], true, function()
											if isKeyCheckAvailable() then
												command_handler("main", binder_menu_navigation["content"]["index"], "")
											end
										end)

										if not need_update_configuration then need_update_configuration = os.clock() end
									end
								end

								imgui.SameLine() -- same

								if imgui.Button(string.format("%s##destroy-hk", faicons["ICON_TRASH"]), imgui.ImVec2(20, 20)) then
									if configuration["CUSTOM"][path[1]][path[2]][path[3]]["keys"] then
										if configuration["CUSTOM"][path[1]][path[2]][path[3]]["keys"]["v"] then
											local result, id = rkeys.isHotKeyDefined(configuration["CUSTOM"][path[1]][path[2]][path[3]]["keys"]["v"])
											if result then rkeys.unRegisterHotKey(id) end
										end

										configuration["CUSTOM"][path[1]][path[2]][path[3]]["keys"] = false

										if not need_update_configuration then need_update_configuration = os.clock() end
									end
								end
							end
						end
					imgui.EndChild()
				end
			else
				imgui.BeginGroup()
					imgui.BeginChild("##navigation", imgui.ImVec2(220, 41))
						imgui.SetCursorPos(imgui.ImVec2(93, 15))
						for index = 1, 2 do
							if im_circle_button("##nav-" .. index, (index == binder_menu_navigation["current"])) then
								binder_menu_navigation["current"] = index
							end if index ~= 2 then imgui.SameLine() end
						end
					imgui.EndChild()

					imgui.SameLine() -- same

					imgui.BeginChild("##another", imgui.ImVec2(400, 41))
						imgui.SetCursorPos(imgui.ImVec2(5, 10))

						if binder_menu_navigation["current"] == 2 then
							imgui.PushItemWidth(220)
							imgui.InputTextWithHint("##search", u8"Поиск по списку", string_found[3], 50)

							imgui.SameLine() -- same

							if imgui.Button(u8"Добавить новую команду", imgui.ImVec2(160, 20)) then
								if not configuration["CUSTOM"]["USERS"]["main"] then configuration["CUSTOM"]["USERS"]["main"] = {} end
								table.insert(configuration["CUSTOM"]["USERS"]["main"], {
									["status"] = true,
									["command"] = "",
									["parametrs_amount"] = 0,
									["keys"] = false,
									["variations"] = { {} }
								})
							end
						else
							imgui.PushItemWidth(390)
							imgui.InputTextWithHint("##search", u8"Поиск по списку", string_found[3], 50)
						end
					imgui.EndChild()
				imgui.EndGroup()

				if binder_menu_navigation["current"] == 1 then
					imgui.SetCursorPosY(118) -- fix Y
					imgui.BeginChild("##lower", imgui.ImVec2(630, 305))
						imgui.SetCursorPos(imgui.ImVec2(5, 4)) -- fix Y

						imgui.CustomButton(u8"#", imgui.ImVec2(25, 20)) imgui.SameLine(nil, 5)
						imgui.CustomButton(faicons["ICON_POWER_OFF"], imgui.ImVec2(30, 20)) imgui.SameLine()
						imgui.CustomButton(faicons["ICON_BANDCAMP"], imgui.ImVec2(25, 20)) imgui.SameLine()
						imgui.CustomButton(u8"Команда", imgui.ImVec2(105, 20)) imgui.SameLine()
						imgui.CustomButton(u8"Краткое описание")

						local sex = configuration["MAIN"]["information"]["sex"] and "female" or "male"
						-- оооо оптимизация

						for index, value in ipairs(ti_system_commands) do
							if string.match(value["index"], str(string_found[3])) or string.match(value["description"], str(string_found[3])) then
								imgui.SetCursorPosX(5)
								imgui.CustomButton(tostring(index), imgui.ImVec2(25, 20))
								imgui.SameLine(nil, 5) -- imgui.NextColumn()

								-- статус команды
								local path = (value["path"][2] == "$sex") and sex or value["path"][2]
								local click, result = im_toggle_button_A("##command_status" .. index, nil, { "CUSTOM", "SYSTEM", path, value["index"], "status" })
								if click then
									if result then
										register_chat_command(value["index"], value["callback"], configuration["CUSTOM"]["SYSTEM"][path][value["index"]])
									else
										sampUnregisterChatCommand(value["index"])
									end
								end imgui.SameLine() -- imgui.NextColumn()

								-- настройка быстрого меню
								if imgui.Button(string.format("%s##command_fast_menu-%s", faicons["ICON_PLUS_CIRCLE"], index), imgui.ImVec2(26, 20)) then
									local is_found = false

									for k, v in ipairs(configuration["MAIN"]["quick_menu"]) do
										if value["callback"] == v["callback"] then
											table.remove(configuration["MAIN"]["quick_menu"], k)
											is_found = true
										end
									end

									if is_found then
										chat(string.format("Команда {HEX}%s{} была исключена из быстрого меню ({HEX}клавиша Z{}).", string.upper(value["index"])))
									else
										local command = string.upper(value["index"])
										table.insert(configuration["MAIN"]["quick_menu"], { ["title"] = command, ["callback"] = value["callback"] })
										chat(string.format("Команда {HEX}%s{} была включена в быстрое меню ({HEX}клавиша Z{}).", string.upper(value["index"])))
									end

									register_quick_menu() -- обновляем быстрое меню
									if not need_update_configuration then need_update_configuration = os.clock() end
								end
								imgui.Hint(string.format("##hcommand_fast_menu-%s", index), u8"Нажмите, чтобы добавить команду в быстрое меню.\nЕсли она уже там есть, то она будет исключена из него.")
								imgui.SameLine() -- imgui.NextColumn()

								if imgui.Button(value["index"], imgui.ImVec2(105, 20)) then
									local settings = configuration["CUSTOM"]["SYSTEM"][path][value["index"]]

									if #settings["variations"] > 0 then
										binder_menu_navigation["current"] = 4
										binder_menu_navigation["content"] = {
											["index"] = index,
											["command"] = value["index"],
											["content"] = new.char[9999](table.concat(settings["variations"][1], "\n")),
											["system"] = 1,
											["settings"] = settings,
											["variations"] = 1,
											["path"] = { "SYSTEM", path, value["index"] }
										}
									else
										chat("В этой команде ничего нельзя изменить.")
									end
								end
								imgui.Hint(string.format("##hcommand_editor-%s", index), u8"Нажмите, чтобы открыть окно редактирования команды.")
								imgui.SameLine() -- imgui.NextColumn()

								imgui.CustomButton(value["description"])
								-- imgui.NextColumn()
							end
						end
					imgui.EndChild()
				elseif binder_menu_navigation["current"] == 2 then
					imgui.SetCursorPosY(118) -- fix Y
					imgui.BeginChild("##custom", imgui.ImVec2(235, 305))
						if configuration["CUSTOM"]["USERS"]["main"] and #configuration["CUSTOM"]["USERS"]["main"] > 0 then
							imgui.SetCursorPos(imgui.ImVec2(5, 4)) -- fix Y

							imgui.CustomButton(u8"#", imgui.ImVec2(25, 20)) imgui.SameLine(nil, 5)
							imgui.CustomButton(faicons["ICON_POWER_OFF"], imgui.ImVec2(30, 20)) imgui.SameLine()
							imgui.CustomButton(faicons["ICON_BANDCAMP"], imgui.ImVec2(25, 20)) imgui.SameLine()
							imgui.CustomButton(u8"Команда", imgui.ImVec2(105, 20))

							for index, value in ipairs(configuration["CUSTOM"]["USERS"]["main"]) do
								if string.match(value["command"], str(string_found[3])) then
									imgui.SetCursorPosX(5)
									imgui.CustomButton(tostring(index), imgui.ImVec2(25, 20))
									imgui.SameLine(nil, 5) -- imgui.NextColumn()

									-- статус команды
									local click, result = im_toggle_button_A("##command_status" .. index, nil, { "CUSTOM", "USERS", "main", index, "status" })
									if click then
										if result then
											register_custom_command(value["command"], index, value)
										else
											sampUnregisterChatCommand(value["command"])
											if value["keys"] then
												if value["keys"]["v"] then
													local result, id = rkeys.isHotKeyDefined(value["keys"]["v"])
													if result then rkeys.unRegisterHotKey(id) end
												end
											end
										end
									end imgui.SameLine() -- imgui.NextColumn()

									-- настройка быстрого меню
									if imgui.Button(string.format("%s##command_fast_menu-%s", faicons["ICON_PLUS_CIRCLE"], index), imgui.ImVec2(26, 20)) then
										local is_found = false

										for k, v in ipairs(configuration["MAIN"]["quick_menu"]) do
											if string.upper(value["command"]) == v["title"] then
												table.remove(configuration["MAIN"]["quick_menu"], k)
												is_found = true
											end
										end

										if is_found then
											chat(string.format("Команда {HEX}%s{} была исключена из быстрого меню ({HEX}клавиша Z{}).", string.upper(value["command"])))
										else
											local command = string.upper(value["command"])
											table.insert(configuration["MAIN"]["quick_menu"], { ["title"] = command, ["callback"] = index })
											chat(string.format("Команда {HEX}%s{} была включена в быстрое меню ({HEX}клавиша Z{}).", string.upper(value["command"])))
										end

										register_quick_menu() -- обновляем быстрое меню
										if not need_update_configuration then need_update_configuration = os.clock() end
									end

									imgui.Hint(string.format("##hcommand_fast_menu-%s", index), u8"Нажмите, чтобы добавить команду в быстрое меню.\nЕсли она уже там есть, то она будет исключена из него.")
									imgui.SameLine() -- imgui.NextColumn()

									if imgui.Button(string.format("%s##%s", value["command"], index), imgui.ImVec2(105, 20)) then
										local settings = configuration["CUSTOM"]["USERS"]["main"][index]
										if not settings["variations"] then settings["variations"] = {} end
										if not settings["variations"][1] then settings["variations"][1] = {} end

										binder_menu_navigation["current"] = 4
										binder_menu_navigation["content"] = {
											["index"] = index,
											["command"] = value["command"],
											["content"] = new.char[9999](table.concat(settings["variations"][1], "\n")),
											["system"] = false,
											["settings"] = settings,
											["variations"] = 1,
											["path"] = { "USERS", "main", index }
										}

										im_input_command = new.char[256](value["command"])
										im_input_parametrs[0] = binder_menu_navigation["content"]["settings"]["parametrs_amount"]
									end
									imgui.Hint(string.format("##hcommand_editor-%s", index), u8"Нажмите, чтобы открыть окно редактирования команды.")
									-- imgui.SameLine() -- imgui.NextColumn()
								end
							end
						else
							imgui.SetCursorPosY(130) -- fixY
							imgui.CenterText(u8"Вы ещё не создали ни одной команды :c")
						end
					imgui.EndChild()

					imgui.SameLine() -- same

					imgui.BeginChild("##low", imgui.ImVec2(385, 305))
						imgui.SetCursorPos(imgui.ImVec2(5, 4)) -- fix Y

						imgui.CustomButton(u8"#", imgui.ImVec2(25, 20)) imgui.SameLine(nil, 5)
						imgui.CustomButton(faicons["ICON_POWER_OFF"], imgui.ImVec2(30, 20)) imgui.SameLine()
						imgui.CustomButton(u8"Действие", imgui.ImVec2(60, 20)) imgui.SameLine()
						imgui.CustomButton(u8"Краткое описание")

						local sex = configuration["MAIN"]["information"]["sex"] and "female" or "male"
						-- оооо оптимизация

						for index, value in ipairs(ti_low_action) do
							if string.match(value["index"], str(string_found[3])) then
								imgui.SetCursorPosX(5)
								imgui.CustomButton(tostring(index), imgui.ImVec2(25, 20))
								imgui.SameLine(nil, 5) -- imgui.NextColumn()

								-- статус команды
								local click, result = im_toggle_button_A("##command_status" .. index, nil, { "CUSTOM", "LOW_ACTION", sex, value["index"], "status" })
								imgui.SameLine() -- imgui.NextColumn()

								if imgui.Button(string.format("%s##action_%s", value["index"], index), imgui.ImVec2(60, 20)) then
									local settings = configuration["CUSTOM"]["LOW_ACTION"][sex][value["index"]]

									binder_menu_navigation["current"] = 4
									binder_menu_navigation["content"] = {
										["index"] = index,
										["command"] = value["index"],
										["content"] = new.char[9999](table.concat(settings["variations"][1], "\n")),
										["system"] = 2,
										["settings"] = settings,
										["variations"] = 1,
										["path"] = { "LOW_ACTION", sex, value["index"] }
									}
								end
								imgui.Hint(string.format("##haction_editor-%s", index), u8"Нажмите, чтобы открыть окно редактирования отыгровки.")
								imgui.SameLine() -- imgui.NextColumn()

								imgui.CustomButton(value["description"])
							end
						end

					imgui.EndChild()
				end
			end
		else
			imgui.CenterText(u8"Будет скоро доступно :)")
		end

	imgui.End()
	imgui.PopStyleVar()
end)
-- !mimgui

-- main
function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
	repeat wait(0) until isSampAvailable()

		local start_time = os.clock()
	checking_relevance_versions_and_files()

	-- ивенты
	addEventHandler("onWindowMessage", function(msg, wparam, lparam)
		if msg == wm.WM_KILLFOCUS then
			if not pause_start then 
				pause_start = { os.clock(), 1 }
				create_assistant_thread("pause_test")
			end
		elseif msg == wm.WM_SETFOCUS then
			--
		elseif msg == wm.WM_RBUTTONDOWN then 
			if isKeyCheckAvailable() then
				create_assistant_thread("fast_interaction_2")
			end
		elseif msg == wm.WM_RBUTTONUP then
			if isKeyCheckAvailable() then
				destroy_assistant_thread("fast_interaction_2")
			end
		elseif msg == 0x100 then
			if wparam == vkeys.VK_ESCAPE then
				local was_found_active_menu = false
				if isKeyCheckAvailable() then
					for index, value in pairs(t_mimgui_render) do
						if value["close"] ~= 0 then
							if value["state"] then
								if not was_found_active_menu or was_found_active_menu < value["close"] then
									was_found_active_menu = value["close"]
								end
							end
						end
					end

					if was_found_active_menu then 
						for index, value in pairs(t_mimgui_render) do
							if was_found_active_menu == value["close"] then
								if value["state"] then
									t_mimgui_render[index]["switch"]()
								end
							end
						end
					end
				end 

				if was_found_active_menu then
					consumeWindowMessage(true, true)
				else
					if not isPauseMenuActive() then
						if not pause_start then 
							pause_start = { os.clock(), 2 }
							create_assistant_thread("pause_test")
						end
					end
				end
			elseif wparam == vkeys.VK_B then
				if isKeyCheckAvailable() then
					global_samp_cursor_status = true
				end
			elseif wparam == vkeys.VK_SPACE then
				if isKeyCheckAvailable() then
					if player_animation then
						clear_animation()
						player_animation = false
						consumeWindowMessage(true, false)
					end
				end
			elseif wparam == vkeys.VK_M then
				if isPlayerPlaying(playerHandle) then
					if isKeyCheckAvailable() then
						open_menu_map = true
					end
				end
			elseif wparam == vkeys.VK_Y then
				if t_accept_the_offer then
					if os.clock() - t_accept_the_offer[2] > 45 then 
						t_accept_the_offer = nil
					else
						if isKeyCheckAvailable() then
							consumeWindowMessage(true, true)
							t_accept_the_offer[3]()
							t_accept_the_offer = nil
						end
					end
				end
			elseif wparam == vkeys.VK_N then
				if t_accept_the_offer then
					if os.clock() - t_accept_the_offer[2] > 45 then 
						t_accept_the_offer = nil
					else
						if isKeyCheckAvailable() then
							consumeWindowMessage(true, true)
							t_accept_the_offer = nil
						end
					end
				end
			end
		elseif msg == 0x101 then
			if wparam == vkeys.VK_X then
				if isKeyCheckAvailable() then
					if global_command_handler then
						consumeWindowMessage(true, false)
						global_break_command = os.clock()
					end
				end
			elseif wparam == vkeys.VK_Z then
				if isKeyCheckAvailable() then
					if not t_mimgui_render["quick_menu"]["state"] then
						local was_found_active_menu = false
						for index, value in pairs(t_mimgui_render) do
							if index ~= "patrol_bar" then
								if value["state"] then was_found_active_menu = true end
							end
						end

						if not was_found_active_menu then
							if targeting_vehicle then
								setVirtualKeyDown(vkeys.VK_RBUTTON, false)
								create_quick_menu("vehicle", targeting_vehicle)
								targeting_vehicle = false
							else
								mimgui_window("quick_menu", true)
							end
						end
					else
						-- if t_quick_menu then t_quick_menu = false end
						mimgui_window("quick_menu", false)
					end
				end
			elseif wparam == vkeys.VK_1 then
				if isKeyCheckAvailable() then
					if isKeyDown(VK_RBUTTON) then
						-- consumeWindowMessage(true, false)
						sampSendChat("/eat")
					elseif isKeyDown(VK_C) then
						consumeWindowMessage(true, false)
						flymode = not flymode
						if flymode then
							lockPlayerControl(true)
							local x, y, z = getActiveCameraCoordinates()

							setFixedCameraPosition(x, y, z, 0.0, 0.0, 0.0)
							camera = {
								["origin"] = {x = x, y = y, z = z},
								["angle"] = {y = 0.0, z = getCharHeading(playerPed) * -1.0},
								["speed"] = 1
							}
						else
							restoreCameraJumpcut()
							setCameraBehindPlayer()
							lockPlayerControl(false)
						end
					end
				end
			elseif wparam == vkeys.VK_2 then
				if isKeyCheckAvailable() then
					if isKeyDown(VK_RBUTTON) then
						-- consumeWindowMessage(true, false)
						sampSendChat("/open")
					end
				end
			elseif wparam == vkeys.VK_3 then
				if isKeyCheckAvailable() then
					if isKeyDown(VK_RBUTTON) then
						-- consumeWindowMessage(true, false)
						command_megafon()
					end
				end
			elseif wparam == vkeys.VK_5 then
				if isKeyCheckAvailable() then
					if isKeyDown(VK_RBUTTON) then
						-- consumeWindowMessage(true, false)
						if #t_smart_suspects > 0 then
							local suspect_id = t_smart_suspects[1]["suspect"]["id"]
							local stars = t_smart_suspects[1]["alleged_violations"][1]["stars"]
							local reason = t_smart_suspects[1]["alleged_violations"][1]["reason"]
							command_su(string.format("%s %s %s", suspect_id, stars, reason))
							-- table.remove(t_smart_suspects, 1)
						end
					end
				end
			elseif wparam == vkeys.VK_H then
				if isKeyCheckAvailable() then
					if isKeyDown(VK_RBUTTON) then
						if isCharSittingInAnyCar(playerPed) then
							b_stroboscopes = not b_stroboscopes
							lua_thread.create(t_stroboscopes)
						end
					else
						if was_start_harvesting then
							if os.clock() - was_start_harvesting[2] < 60 then
								local textdraw_id = was_start_harvesting[1]
								if sampTextdrawIsExists(textdraw_id) then
									for index = textdraw_id, textdraw_id + 100 do
										if index ~= textdraw_id + 3 and index ~= textdraw_id + 4 then
											sampSendClickTextdraw(index)
										end
									end
								else was_start_harvesting = nil end
							else was_start_harvesting = nil end
						end
					end
				end
			elseif wparam == vkeys.VK_B then
				if isKeyCheckAvailable() then
					global_samp_cursor_status = false
				end
			elseif wparam == vkeys.VK_M then
				if isPlayerPlaying(playerHandle) then
					if isKeyCheckAvailable() then
						open_menu_map = false
					end
				end
			elseif wparam == vkeys.VK_J then
				if configuration["MAIN"]["settings"]["quick_lock_doors"] then
					for vehicle_id, vehicle_information in pairs(t_smart_vehicle["vehicle"]) do
						local result, vehicle_handle = sampGetCarHandleBySampVehicleId(vehicle_id)
						if result then
							if getDistanceToVehicle(vehicle_handle) < 7 then
								if wasKeyPressed(vkeys["VK_J"]) then
									if isKeyCheckAvailable() then
										local normal_vehicle_id = getCarModel(vehicle_handle) - 399
										local word = getCarDoorLockStatus(vehicle_handle) == 0 and "закрыто" or "открыто"
										chat(string.format("Ваше транспортное средство (%s {HEX}%s{} #{HEX}%s{}) было %s умным ключом.", tf_vehicle_type_name[3][t_vehicle_type[normal_vehicle_id]], t_vehicle_name[normal_vehicle_id], vehicle_id, word))
										sampSendChat(string.format("/lock %s", vehicle_information["type"]))
									end
								end
							end
						end
					end
				end
			end
		end
	end)

	-- калибровка генератора псевдослучайных чисел
	math.randomseed(os.time())

	-- регистрация системных команд
	local sex = configuration["MAIN"]["information"]["sex"] and "female" or "male"

	for index, value in ipairs(ti_system_commands) do
		local command, callback = value["index"], value["callback"]
		if not sampIsChatCommandDefined(command) and type(_G[callback]) == "function" then -- проверяем регистрацию команды и существование callback'a
			local block_command = (value["path"][2] == "$sex") and sex or value["path"][2]
			local settings = configuration["CUSTOM"][value["path"][1]][block_command][command] -- получаем указатель на конфигурацию команды
			register_chat_command(command, callback, settings)
		else chat("Команда {HEX}", command, "{}не имеет callback'a или уже зарегистрирована.") end
	end

	for index, value in ipairs(configuration["CUSTOM"]["USERS"]["main"]) do
		local command = value["command"]
		if command ~= "" then
			if not sampIsChatCommandDefined(command) then
				register_custom_command(command, index, value)
			end
		end
	end

	sampRegisterChatCommand("fix_ad", function()
		sampSendDialogResponse(224, 0, 0, "")
	end)

	-- потекли потоки
	lua_thread.create(th_render_player_text)
	lua_thread.create(th_helper_assistant)
	lua_thread.create(th_smart_suspects)
	lua_thread.create(th_role_play_weapons)

	print(string.format("Общее время загрузки игрового помощника: %s\n\n", os.clock() - start_time))

	while true do wait(0)
		if wasKeyPressed(vkeys.VK_RCONTROL) then
			if isKeyCheckAvailable() then
				if not isCharSittingInAnyCar(playerPed) then
					if pricel then
						create_player_text(0, 2, "ПРИЦЕЛ {C22222}СНЯТ{e6e6fa} С РЕЖИМА УДЕРЖАНИЯ")
					else
						create_player_text(0, 2.5, "ПРИЦЕЛ {C22222}ПЕРЕВЕДЁН{e6e6fa} В РЕЖИМ УДЕРЖАНИЯ")
					end pricel = not pricel
				end
			end
		end

		if isPlayerPlaying(playerHandle) then -- tnx FYP
	      if isKeyDown(VK_M) then
	      	if isKeyCheckAvailable() then
		      	local menuPtr = 0x00BA6748
		        writeMemory(menuPtr + 0x33, 1, 1, false) -- activate menu
		        -- wait for a next frame
		        wait(0)
		        writeMemory(menuPtr + 0x15C, 1, 1, false) -- textures loaded
		        writeMemory(menuPtr + 0x15D, 1, 5, false) -- current menu
		        if reduceZoom or true then
		          writeMemory(menuPtr + 0x64, 4, representFloatAsInt(300.0), false)
		        end
		        while isKeyDown(VK_M) do
		          wait(80)
		        end
		        writeMemory(menuPtr + 0x32, 1, 1, false) -- close menu
		    end
	      end
	    end

		if global_samp_cursor_status then
			if sampGetCursorMode() ~= 3 then sampSetCursorMode(3) end
			destroy_samp_cursor = false
		else
			if not destroy_samp_cursor then
				if sampGetCursorMode() ~= 0 then sampSetCursorMode(0) end
				destroy_samp_cursor = true
			end
		end

        if pricel then memory.write(12 + 12006488, 2, 128, false) end

		if isKeyDown(VK_RBUTTON) then
			local result, char = getCharPlayerIsTargeting(playerHandle)
			if result then
				local result, player_id = sampGetPlayerIdByCharHandle(char)
				if result then
					if targeting_player ~= player_id then 
						if targeting_vehicle then targeting_vehicle = nil end
						targeting_player = player_id
					end
				end
			end
		end

		--[[if player_animation then
			if not isCharPlayingAnim(playerPed, player_animation) then
				player_animation = nil
			end
		end--]]

		if flymode then
			local mouseX, mouseY = getPcMouseMovement()
			local mouseX = mouseX / 4.0
			local mouseY = mouseY / 4.0

			camera["angle"]["z"] = camera["angle"]["z"] + mouseX
			camera["angle"]["y"] = camera["angle"]["y"] + mouseY

			if camera["angle"]["z"] > 360 then camera["angle"]["z"] = camera["angle"]["z"] - 360 end
			if camera["angle"]["z"] < 0 then camera["angle"]["z"] = camera["angle"]["z"] + 360 end
			if camera["angle"]["y"] > 89 then camera["angle"]["y"] = 89 end
			if camera["angle"]["y"] < -89 then camera["angle"]["y"] = -89 end

			local currentZ = camera["angle"]["z"] + 180
			local currentY = camera["angle"]["y"] * -1

			local radianZ = math.rad(currentZ)
			local radianY = math.rad(currentY)
			local sinusZ = math.sin(radianZ)
			local cosinusZ = math.cos(radianZ)
			local sinusY = math.sin(radianY)
			local cosinusY = math.cos(radianY)

			local sinusZ = sinusZ * cosinusY
			local cosinusZ = cosinusZ * cosinusY
			local sinusZ = sinusZ * 10.0
			local cosinusZ = cosinusZ * 10.0
			local sinusY = sinusY * 10.0
			local position_plX = camera["origin"]["x"] + sinusZ
			local position_plY = camera["origin"]["y"] + cosinusZ
			local position_plZ = camera["origin"]["z"] + sinusY
			local angle_plZ = camera["angle"]["z"] * -1.0

			if isKeyDown(VK_W) then
				local radianZ = math.rad(camera["angle"]["z"])
				local radianY = math.rad(camera["angle"]["y"])
				local sinusZ = math.sin(radianZ)
				local cosinusZ = math.cos(radianZ)
				local sinusY = math.sin(radianY)
				local cosinusY = math.cos(radianY)
				local sinusZ = sinusZ * cosinusY
				local cosinusZ = cosinusZ * cosinusY
				local sinusZ = sinusZ * camera["speed"]
				local cosinusZ = cosinusZ * camera["speed"]
				local sinusY = sinusY * camera["speed"]
				camera["origin"]["x"] = camera["origin"]["x"] + sinusZ
				camera["origin"]["y"] = camera["origin"]["y"] + cosinusZ
				camera["origin"]["z"] = camera["origin"]["z"] + sinusY
				setFixedCameraPosition(camera["origin"]["x"], camera["origin"]["y"], camera["origin"]["z"], 0.0, 0.0, 0.0)
			end

			if isKeyDown(VK_S) then
				local currentZ = camera["angle"]["z"] + 180.0
				local currentY = camera["angle"]["y"] * -1.0
				local radianZ = math.rad(currentZ)
				local radianY = math.rad(currentY)
				local sinusZ = math.sin(radianZ)
				local cosinusZ = math.cos(radianZ)
				local sinusY = math.sin(radianY)
				local cosinusY = math.cos(radianY)
				local sinusZ = sinusZ * cosinusY
				local cosinusZ = cosinusZ * cosinusY
				local sinusZ = sinusZ * camera["speed"]
				local cosinusZ = cosinusZ * camera["speed"]
				local sinusY = sinusY * camera["speed"]
				camera["origin"]["x"] = camera["origin"]["x"] + sinusZ
				camera["origin"]["y"] = camera["origin"]["y"] + cosinusZ
				camera["origin"]["z"] = camera["origin"]["z"] + sinusY
				setFixedCameraPosition(camera["origin"]["x"], camera["origin"]["y"], camera["origin"]["z"], 0.0, 0.0, 0.0)
			end

			if isKeyDown(VK_A) then
				local currentZ = camera["angle"]["z"] - 90.0
				local radianZ = math.rad(currentZ)
				local radianY = math.rad(camera["angle"]["y"])
				local sinusZ = math.sin(radianZ)
				local cosinusZ = math.cos(radianZ)
				local sinusZ = sinusZ * camera["speed"]
				local cosinusZ = cosinusZ * camera["speed"]
				camera["origin"]["x"] = camera["origin"]["x"] + sinusZ
				camera["origin"]["y"] = camera["origin"]["y"] + cosinusZ
				setFixedCameraPosition(camera["origin"]["x"], camera["origin"]["y"], camera["origin"]["z"], 0.0, 0.0, 0.0)
			end

			if isKeyDown(VK_D) then
				local currentZ = camera["angle"]["z"] + 90.0
				local radianZ = math.rad(currentZ)
				local radianY = math.rad(camera["angle"]["y"])
				local sinusZ = math.sin(radianZ)
				local cosinusZ = math.cos(radianZ)
				local sinusZ = sinusZ * camera["speed"]
				local cosinusZ = cosinusZ * camera["speed"]
				camera["origin"]["x"] = camera["origin"]["x"] + sinusZ
				camera["origin"]["y"] = camera["origin"]["y"] + cosinusZ
				setFixedCameraPosition(camera["origin"]["x"], camera["origin"]["y"], camera["origin"]["z"], 0.0, 0.0, 0.0)
			end

			if isKeyDown(VK_SPACE) then
				camera["origin"]["z"] = camera["origin"]["z"] + camera["speed"]
				setFixedCameraPosition(camera["origin"]["x"], camera["origin"]["y"], camera["origin"]["z"], 0.0, 0.0, 0.0)
			end

			if isKeyDown(VK_SHIFT) then
				camera["origin"]["z"] = camera["origin"]["z"] - camera["speed"]
				setFixedCameraPosition(camera["origin"]["x"], camera["origin"]["y"], camera["origin"]["z"], 0.0, 0.0, 0.0)
			end

			local radianZ = math.rad(camera["angle"]["z"])
			local radianY = math.rad(camera["angle"]["y"])
			local sinusZ = math.sin(radianZ)
			local cosinusZ = math.cos(radianZ)
			local sinusY = math.sin(radianY)
			local cosinusY = math.cos(radianY)
			local sinusZ = sinusZ * cosinusY
			local cosinusZ = cosinusZ * cosinusY
			local sinusZ = sinusZ * 1.0
			local cosinusZ = cosinusZ * 1.0
			local sinusY = sinusY * 1.0
			local point_atX = camera["origin"]["x"] + sinusZ
			local point_atY = camera["origin"]["y"] + cosinusZ
			local point_atZ = camera["origin"]["z"] + sinusY

			pointCameraAtPoint(point_atX, point_atY, point_atZ, 2)

			if isKeyDown(187) then
				camera["speed"] = camera["speed"] + 0.005
			end

			if isKeyDown(189) then
				camera["speed"] = camera["speed"] - 0.005
				if camera["speed"] < 0.001 then camera["speed"] = 0.001 end
			end
		end

		if need_update_configuration then
			if os.clock() - need_update_configuration > 10 then
				configuration_save(configuration)
				need_update_configuration = nil
			end
		end
	end
end
-- !main

-- thread
function th_render_player_text()
	local font = renderCreateFont("tahoma", 6, font_flag.BOLD + font_flag.SHADOW)

	function create_player_text(index, timer, text)
		if not index then return end
		table.insert(t_player_text, {
			["type"] = index,
			["clock"] = os.clock(),
			["timer"] = timer or 1,
			["text"] = text or ""
		})
	end

	function destroy_player_text(index)
		if not index then return end
		if not t_player_text[index] then return end
		if not t_player_text[index]["destroy"] then
			t_player_text[index]["destroy"] = os.clock()
		end
	end

	while script_is_alive do wait(0)
		if #t_player_text > 0 then
			local x, y, z

			if isCharInAnyCar(playerPed) then
				local vehicle = storeCarCharIsInNoSave(playerPed)
				local model = getCarModel(vehicle)
				x, y, z = getOffsetFromCarInWorldCoords(vehicle, (t_vehicle_type[model - 399] == 2 or t_vehicle_type[model - 399] == 8) and 0.5 or 1.2, 0.0, 0.15)
			else
				x, y, z = getOffsetFromCharInWorldCoords(playerPed, 0.33, 0.0, 0.15)
			end

			if isPointOnScreen(x, y, z) then
				local w, h = convert3DCoordsToScreen(x, y, z)

				for index, value in ipairs(t_player_text) do
					local h = h + 10 * index

					local text_color = 0xFFe6e6fa
					if value["destroy"] then
						local timer_delta = os.clock() - value["destroy"]
						if timer_delta < 0.5 then
							local percent = timer_delta * 5
							text_color = join_argb(255 - (255 * percent), 230, 230, 250)
						else 
							table.remove(t_player_text, index)
						end
					end

					if value["type"] == 0 then
						if os.clock() - value["clock"] > value["timer"] then destroy_player_text(index) end
						renderFontDrawText(font, value["text"], w, h, text_color)
					elseif value["type"] == 1 then
						if os.clock() - value["clock"] > 5.5 then
							destroy_player_text(index)
						else
							local text = string.format("HEALME ANIMATION {C22222}%0.3f{e6e6fa} SECONDS", 5.5 - (os.clock() - value["clock"]))
							renderFontDrawText(font, text, w, h, text_color)
						end
					elseif value["type"] == 2 then
						local remaining_time_action = 600 - math.floor(os.clock() - value["clock"])
						local text = string.format("{C22222}%d{e6e6fa} MINUTES {C22222}%d{e6e6fa} SECONDS", math.floor(remaining_time_action / 60), math.fmod(remaining_time_action, 60))
						renderFontDrawText(font, text, w, h, text_color)
					elseif value["type"] == 3 then
						if not player_animation then destroy_player_text(index) end
						renderFontDrawText(font, "ЧТОБЫ ОСТАНОВИТЬ АНИМАЦИЮ НАЖМИТЕ {C22222}ПРОБЕЛ", w, h, text_color)
					elseif value["type"] == 4 then
						if not time_take_ads then destroy_player_text(index) end

						local integer, float = math.modf(os.clock())
						local dots
						if float >= 0.0 and float < 0.4 then dots = "."
						elseif float >= 0.4 and float < 0.8 then dots = ".."
						elseif float >= 0.8 and float < 1.0 then dots = "..." end

						if t_mimgui_render["editor_ads"]["state"] then
							renderFontDrawText(font, string.format("ОБЪЯВЛЕНИЕ НАХОДИТСЯ НА ПРОВЕРКЕ%s", dots), w, h, text_color)
						else
							renderFontDrawText(font, string.format("ОЖИДАЕМ ПОЯВЛЕНИЯ НОВЫХ ОБЪЯВЛЕНИЙ%s", dots), w, h, text_color)
						end
					end
				end
			end
		end
	end
end

function t_stroboscopes()
	while true do wait(0)
		if isCharInAnyCar(playerPed) and configuration["MAIN"]["settings"]["stroboscopes"] then
			local car = storeCarCharIsInNoSave(playerPed)
			local driverPed = getDriverOfCar(car)

			if b_stroboscopes and playerPed == driverPed then

				local ptr = getCarPointer(car) + 1440
				forceCarLights(car, 2)
				wait(50)
				stroboscopes(7086336, ptr, 2, 0, 1, 3)

				while b_stroboscopes do
					wait(0)
						for i = 1, 12 do
							wait(100)
							stroboscopes(7086336, ptr, 2, 0, 1, 0)
							wait(100)
							stroboscopes(7086336, ptr, 2, 0, 0, 0)
							stroboscopes(7086336, ptr, 2, 0, 1, 1)
							wait(100)
							stroboscopes(7086336, ptr, 2, 0, 0, 1)
							stroboscopes(7086336, ptr, 2, 0, 1, 0)
							wait(100)
							stroboscopes(7086336, ptr, 2, 0, 1, 0)
							stroboscopes(7086336, ptr, 2, 0, 1, 1)
							if not b_stroboscopes or not isCharInAnyCar(playerPed) then break end
						end

						if not b_stroboscopes or not isCharInAnyCar(playerPed) then break end

						for i = 1, 6 do
							wait(80)
							stroboscopes(7086336, ptr, 2, 0, 1, 3)
							stroboscopes(7086336, ptr, 2, 0, 0, 0)
							wait(80)
							stroboscopes(7086336, ptr, 2, 0, 1, 0)
							wait(80)
							stroboscopes(7086336, ptr, 2, 0, 0, 0)
							wait(80)
							stroboscopes(7086336, ptr, 2, 0, 1, 0)
							if not b_stroboscopes or not isCharInAnyCar(playerPed) then break end
							wait(300)
							stroboscopes(7086336, ptr, 2, 0, 0, 1)
							wait(80)
							stroboscopes(7086336, ptr, 2, 0, 1, 1)
							wait(80)
							stroboscopes(7086336, ptr, 2, 0, 0, 1)
							wait(80)
							stroboscopes(7086336, ptr, 2, 0, 1, 1)
							if not b_stroboscopes or not isCharInAnyCar(playerPed) then break end
						end

						if not b_stroboscopes or not isCharInAnyCar(playerPed) then break end

						for i = 1, 3 do
							wait(60)
							stroboscopes(7086336, ptr, 2, 0, 1, 3)
							stroboscopes(7086336, ptr, 2, 0, 1, 0)
							stroboscopes(7086336, ptr, 2, 0, 0, 1)
							wait(60)
							stroboscopes(7086336, ptr, 2, 0, 1, 1)
							wait(60)
							stroboscopes(7086336, ptr, 2, 0, 0, 1)
							wait(60)
							stroboscopes(7086336, ptr, 2, 0, 1, 1)
							wait(60)
							stroboscopes(7086336, ptr, 2, 0, 0, 1)
							wait(60)
							stroboscopes(7086336, ptr, 2, 0, 1, 1)
							wait(60)
							stroboscopes(7086336, ptr, 2, 0, 0, 0)
							wait(60)
							if not b_stroboscopes or not isCharInAnyCar(playerPed) then break end
							stroboscopes(7086336, ptr, 2, 0, 1, 0)
							wait(60)
							stroboscopes(7086336, ptr, 2, 0, 0, 0)
							wait(350)
							stroboscopes(7086336, ptr, 2, 0, 1, 0)
							stroboscopes(7086336, ptr, 2, 0, 0, 1)
							wait(60)
							if not b_stroboscopes or not isCharInAnyCar(playerPed) then break end
							stroboscopes(7086336, ptr, 2, 0, 1, 1)
							stroboscopes(7086336, ptr, 2, 0, 0, 0)
							wait(50)
							stroboscopes(7086336, ptr, 2, 0, 1, 0)
							stroboscopes(7086336, ptr, 2, 0, 0, 1)
							wait(50)
							stroboscopes(7086336, ptr, 2, 0, 1, 1)
							stroboscopes(7086336, ptr, 2, 0, 0, 0)
							wait(100)
							stroboscopes(7086336, ptr, 2, 0, 1, 1)
							stroboscopes(7086336, ptr, 2, 0, 1, 1)
							wait(80)
							stroboscopes(7086336, ptr, 2, 0, 0, 1)
							stroboscopes(7086336, ptr, 2, 0, 0, 0)
							wait(100)
							if not b_stroboscopes or not isCharInAnyCar(playerPed) then break end
							stroboscopes(7086336, ptr, 2, 0, 1, 1)
							stroboscopes(7086336, ptr, 2, 0, 1, 0)
							wait(80)
							stroboscopes(7086336, ptr, 2, 0, 0, 1)
							stroboscopes(7086336, ptr, 2, 0, 0, 0)
							wait(100)
							stroboscopes(7086336, ptr, 2, 0, 0, 1)
							stroboscopes(7086336, ptr, 2, 0, 1, 0)
							wait(80)
							stroboscopes(7086336, ptr, 2, 0, 1, 1)
							stroboscopes(7086336, ptr, 2, 0, 0, 0)
							if not b_stroboscopes or not isCharInAnyCar(playerPed) then break end
						end

						if not b_stroboscopes or not isCharInAnyCar(playerPed) then break end
				end return false
			end
		end
	end
end

function th_helper_assistant()
	local last_update_database = os.clock()
	local font = renderCreateFont("tahoma", 8, font_flag.BOLD + font_flag.SHADOW)

	local assistant_threads = {
		["quick_open_door"] = false,
		["map_marker"] = false,
		["procedures_performed"] = false,
		["normal_speedometer_update"] = false,
		["fast_interaction"] = false,
		["fast_interaction_2"] = false,
		["static_time"] = false,
		["time_take_ads"] = false,
		["pause_test"] = false
	}

	local quick_open_door = {
		{ ["position"] = { ["x"] = 1701.126, ["y"] = 943.875, ["z"] = 1030.426 }, ["callback"] = function() sampSendChat("/fbi") end },
		{ ["position"] = { ["x"] = 1697.913, ["y"] = 943.875, ["z"] = 1030.400 }, ["callback"] = function() sampSendChat("/fbi") end },
		{ ["position"] = { ["x"] = 1695.624, ["y"] = 945.420, ["z"] = 1030.400 }, ["callback"] = function() sampSendChat("/fbi") end },
		{ ["position"] = { ["x"] = 1757.240, ["y"] = -27.291, ["z"] = 997.362 }, ["callback"] = function() sampSendChat("/d") end },
		{ ["position"] = { ["x"] = 1758.653, ["y"] = -18.524, ["z"] = 997.362 }, ["callback"] = function() sampSendChat("/d") end },
		{ ["position"] = { ["x"] = 1765.038, ["y"] = -18.524, ["z"] = 997.362 }, ["callback"] = function() sampSendChat("/d") end },
		{ ["position"] = { ["x"] = 1766.635, ["y"] = -34.341, ["z"] = 995.142 }, ["callback"] = function() sampSendChat("/d") end },
		{ ["position"] = { ["x"] = 1756.333, ["y"] = -38.139, ["z"] = 995.026 }, ["callback"] = function() sampSendChat("/d") end },
		{ ["position"] = { ["x"] = 1786.014, ["y"] = -35.866, ["z"] = 1000.930 }, ["callback"] = function() sampSendChat("/d") end },
		{ ["position"] = { ["x"] = -85.338, ["y"] = 2430.111, ["z"] = 1179.772 }, ["callback"] = function() sampSendChat("/jaildoor") end },
		{ ["position"] = { ["x"] = -80.133, ["y"] = 2430.111, ["z"] = 1179.771 }, ["callback"] = function() sampSendChat("/jaildoor") end },
		{ ["position"] = { ["x"] = -74.907, ["y"] = 2430.111, ["z"] = 1179.776 }, ["callback"] = function() sampSendChat("/jaildoor") end },
		{ ["position"] = { ["x"] = -69.704, ["y"] = 2430.111, ["z"] = 1179.768 }, ["callback"] = function() sampSendChat("/jaildoor") end },
		{ ["position"] = { ["x"] = -64.482, ["y"] = 2430.111, ["z"] = 1179.775 }, ["callback"] = function() sampSendChat("/jaildoor") end },
		{ ["position"] = { ["x"] = -64.490, ["y"] = 2439.537, ["z"] = 1179.760 }, ["callback"] = function() sampSendChat("/jaildoor") end },
		{ ["position"] = { ["x"] = -69.717, ["y"] = 2439.537, ["z"] = 1179.769 }, ["callback"] = function() sampSendChat("/jaildoor") end },
		{ ["position"] = { ["x"] = -74.912, ["y"] = 2439.537, ["z"] = 1179.773 }, ["callback"] = function() sampSendChat("/jaildoor") end },
		{ ["position"] = { ["x"] = -80.131, ["y"] = 2439.537, ["z"] = 1179.770 }, ["callback"] = function() sampSendChat("/jaildoor") end },
		{ ["position"] = { ["x"] = -85.343, ["y"] = 2439.537, ["z"] = 1179.761 }, ["callback"] = function() sampSendChat("/jaildoor") end },
		{ ["position"] = { ["x"] = -66.692, ["y"] = 2427.091, ["z"] = 1183.615 }, ["callback"] = function() sampSendChat("/jaildoor") end },
		{ ["position"] = { ["x"] = -71.907, ["y"] = 2427.091, ["z"] = 1183.614 }, ["callback"] = function() sampSendChat("/jaildoor") end },
		{ ["position"] = { ["x"] = -77.112, ["y"] = 2427.091, ["z"] = 1183.616 }, ["callback"] = function() sampSendChat("/jaildoor") end },
		{ ["position"] = { ["x"] = -82.322, ["y"] = 2427.091, ["z"] = 1183.622 }, ["callback"] = function() sampSendChat("/jaildoor") end },
		{ ["position"] = { ["x"] = -87.547, ["y"] = 2427.091, ["z"] = 1183.610 }, ["callback"] = function() sampSendChat("/jaildoor") end },
		{ ["position"] = { ["x"] = -66.693, ["y"] = 2442.646, ["z"] = 1183.609 }, ["callback"] = function() sampSendChat("/jaildoor") end },
		{ ["position"] = { ["x"] = -71.910, ["y"] = 2442.646, ["z"] = 1183.608 }, ["callback"] = function() sampSendChat("/jaildoor") end },
		{ ["position"] = { ["x"] = -77.111, ["y"] = 2442.646, ["z"] = 1183.606 }, ["callback"] = function() sampSendChat("/jaildoor") end },
		{ ["position"] = { ["x"] = -82.329, ["y"] = 2442.646, ["z"] = 1183.608 }, ["callback"] = function() sampSendChat("/jaildoor") end },
		{ ["position"] = { ["x"] = -87.541, ["y"] = 2442.646, ["z"] = 1183.603 }, ["callback"] = function() sampSendChat("/jaildoor") end }
	}

	-- global functions
	function create_map_marker(position)
		table.insert(t_map_markers, {
			["position"] = position,
			["marker"] = false,
			["point3"] = false,
			["time"] = os.time()
		})

		create_assistant_thread("map_marker")
	end

	function destroy_map_marker(position)
		if not (position["y"] and position["z"]) then
			local index = position["x"]
			if t_map_markers[index] then 
				table.remove(t_map_markers, index)
				if #t_map_markers == 0 then destroy_assistant_thread("map_marker") end
			end
		else
			for index, value in ipairs(t_map_markers) do
				local distance = getDistanceBetweenCoords3d(position["x"], position["y"], position["z"], value["position"]["x"], value["position"]["y"], value["position"]["z"])
				if distance < 0.5 then
					table.remove(t_map_markers, index)
					if #t_map_markers == 0 then destroy_assistant_thread("map_marker") end
				end
			end
		end
	end

	function create_offer(index, callback)
		t_accept_the_offer = { index, os.clock(), callback }
	end

	function create_quick_menu(index, input)
		if t_mimgui_render["quick_menu"]["state"] then return false end

		local function test_distance(handle, maximum_distance, entity)
			local getted = entity and doesVehicleExist(handle) or doesCharExist(handle)
			if not getted then 
				for index, value in ipairs(t_quick_menu) do 
					if value["distance"] then value["color"] = 0xFFA0A0A0 end
				end

				chat(entity and "Этот транспорт находится слишком далеко от Вас." or "Этот игрок находится слишком далеко от Вас.")
				return false
			end

			local distance = entity and getDistanceToVehicle(handle) or getDistanceToPlayer(handle)
			if distance > maximum_distance then
				for index, value in ipairs(t_quick_menu) do
					if value["distance"] then 
						if distance > value["distance"] then
							value["color"] = 0xFFA0A0A0
						end
					end
				end

				chat(entity and "Этот транспорт находится слишком далеко от Вас." or "Этот игрок находится слишком далеко от Вас.")
				return false
			end

			for index, value in ipairs(t_quick_menu) do
				if value["distance"] then 
					value["color"] = (distance > value["distance"]) and 0xFFA0A0A0 or nil
				end
			end return true
		end

		local menu = {
			["char"] = {
				{
					["title"] = u8"PRESENT",
					["callback"] = function()
						if test_distance(input["player_handle"], 10, false) then
							sampSendChat(string.format("/present %s", input["player_id"]))
						end
					end,
					["distance"] = 10,
					["color"] = (input["distance"] > 10) and 0xFFA0A0A0 or nil
				},
				{
					["title"] = u8"ALLOW",
					["callback"] = function()
						if test_distance(input["player_handle"], 10, false) then
							sampSendChat(string.format("/allow %s", input["player_id"])) 
						end
					end,
					["distance"] = 10,
					["color"] = (input["distance"] > 10) and 0xFFA0A0A0 or nil
				},
				{
					["title"] = u8"GIVE",
					["callback"] = function() 
						if test_distance(input["player_handle"], 10, false) then
							sampSendChat(string.format("/give %s", input["player_id"])) 
						end
					end,
					["distance"] = 10,
					["color"] = (input["distance"] > 10) and 0xFFA0A0A0 or nil
				},
				{
					["title"] = u8"HI",
					["callback"] = function() 
						if test_distance(input["player_handle"], 10, false) then
							sampSendChat(string.format("/hi %s", input["player_id"])) 
						end
					end,
					["distance"] = 10,
					["color"] = (input["distance"] > 10) and 0xFFA0A0A0 or nil
				},
				{
					["title"] = u8"МЕНЮ",
					["callback"] = function()
						t_quick_menu = false
					end
				}
			},
			["vehicle"] = {
				{
					["title"] = u8"PICK",
					["callback"] = function()
						if test_distance(input["vehicle_handle"], 10, true) then
							sampSendChat("/pick")
						end
					end,
					["distance"] = 10,
					["color"] = (input["distance"] > 10) and 0xFFA0A0A0 or nil
				},
				{
					["title"] = u8"PUT",
					["callback"] = function() 
						if test_distance(input["vehicle_handle"], 10, true) then
							sampSendChat("/put") 
						end
					end,
					["distance"] = 10,
					["color"] = (input["distance"] > 10) and 0xFFA0A0A0 or nil
				},
				{
					["title"] = "LOCK",
					["callback"] = function() 
						if not test_distance(input["vehicle_handle"], 20, true) then return false end

						if t_smart_vehicle["vehicle"][input["vehicle_id"]] then
						    local word = getCarDoorLockStatus(input["vehicle_handle"]) == 0 and "закрыто" or "открыто"
							chat(string.format("Ваше транспортное средство (%s {HEX}%s{} #{HEX}%s{}) было %s умным ключом.", tf_vehicle_type_name[3][t_vehicle_type[input["normal_model"]]], t_vehicle_name[input["normal_model"]], input["vehicle_id"], word))
							sampSendChat(string.format("/lock %s", t_smart_vehicle["vehicle"][input["vehicle_id"]]["type"]))
						else
						    local buffer = t_quick_menu
						    t_quick_menu = {}
						    for index = 1, 8 do
						        t_quick_menu[index] = {
						        	["title"] = string.format("%s", index),
						        	["callback"] = function() sampSendChat(string.format("/lock %s", index)) end
						        }
						    end

						    table.insert(t_quick_menu, {
						        ["title"] = u8"ВЕРНУТЬСЯ",
						       	["callback"] = function() t_quick_menu = buffer end
						    })
						end
					end,
					["distance"] = 20,
					["color"] = (input["distance"] > 20) and 0xFFA0A0A0 or nil
				},
				{
					["title"] = "FIX",
					["callback"] = function()
						if test_distance(input["vehicle_handle"], 10, true) then
							sampSendChat("/fix") 
						end
					end,
					["distance"] = 10,
					["color"] = (input["distance"] > 10) and 0xFFA0A0A0 or nil
				},
				{
					["title"] = u8"МЕГАФОН",
					["callback"] = function(x, y, z)
						if not test_distance(input["vehicle_handle"], 55, true) then return false end
						local player_handle = getDriverOfCar(input["vehicle_handle"])
						local result, player_id = sampGetPlayerIdByCharHandle(player_handle)
						if result then
							local vehicle_model = getCarModel(input["vehicle_handle"])
							command_megafon(player_id, vehicle_model)
							return true
						end
					end,
					["distance"] = 55,
					["color"] = (input["distance"] > 55) and 0xFFA0A0A0 or nil
				},
				{
					["title"] = u8"МЕНЮ",
					["callback"] = function()
						t_quick_menu = false
					end
				}
			}
		}

		if menu[index] then
			t_quick_menu = menu[index]
			mimgui_window("quick_menu", true)
		end
	end

	function create_assistant_thread(index)
		if index then
			assistant_threads[index] = true
		end
	end

	function destroy_assistant_thread(index)
		if index then
			assistant_threads[index] = false
		end
	end
	-- 

	create_assistant_thread("normal_speedometer_update")
	create_assistant_thread("fast_interaction")
	create_assistant_thread("static_time") 

	while script_is_alive do wait(0)
		if isPlayerPlaying(PLAYER_HANDLE) then 
			local x, y, z = getCharCoordinates(playerPed)
			
			if assistant_threads["quick_open_door"] then
				if configuration["MAIN"]["settings"]["quick_open_door"] then
					for index, value in ipairs(quick_open_door) do
						local distance = getDistanceBetweenCoords3d(x, y, z, value["position"]["x"], value["position"]["y"], value["position"]["z"])
						if distance < 3 then
							local sx, sy = convert3DCoordsToScreen(value["position"]["x"], value["position"]["y"], value["position"]["z"])
							local text = string.format("Для взаимодействия нажмите клавишу %sJ{FFFFFF}.", configuration["MAIN"]["settings"]["script_color"])
							local fix = renderGetFontDrawTextLength(font, text)
							-- renderDrawBox(sx - 35, sy, 80, 15, 0x69696969)
							renderFontDrawText(font, text, sx - 110, sy + 1, 0xFFFFFFFF)

							if distance < 1 then
								if wasKeyPressed(vkeys.VK_J) then value["callback"]() end 
							end
						end
					end
				end
			end

			if assistant_threads["map_marker"] then
				for index, value in ipairs(t_map_markers) do
					if not value["marker"] then
						value["marker"] = addBlipForCoord(value["position"]["x"], value["position"]["y"], value["position"]["z"])
						value["point3"] = createUser3dMarker(value["position"]["x"], value["position"]["y"], value["position"]["z"] + 1)
						local color = configuration["MAIN"]["settings"]["timestamp_color"] .. "FF"
						changeBlipColour(value["marker"], color)
					end

					local distance = getDistanceBetweenCoords3d(x, y, z, value["position"]["x"], value["position"]["y"], value["position"]["z"])
					if distance < 20 then
						local delta = os.time() - value["time"]
						local minute, second = math.floor(delta / 60), math.fmod(delta, 60)
						chat(string.format("Вы достигли точки назначения. Время в пути составило: {HEX}%s{} мин. {HEX}%s{} сек.", minute, second))

						removeBlip(value["marker"])
						removeUser3dMarker(value["point3"])
						destroy_map_marker({ ["x"] = index })
					end
				end
			end

			if assistant_threads["procedures_performed"] then
				if not procedures_performed then 
					destroy_assistant_thread("procedures_performed")
				else
					for index, value in ipairs(procedures_performed) do
						if os.time() - value["time"] > 60 then
							if value["is"] then
								chat(string.format("Вы снова можете провести процедуру {HEX}%s{} для больного {HEX}%s{}.", value["procedure"], string.gsub(value["nickname"], "_", " ")))
								local player_id = sampGetPlayerIdByNickname(value["nickname"])

								if player_id and isPlayerConnected(player_id) then
									chat("Если Вы желаете открыть диалог лечения пациента нажмите {HEX}Y{}.")
									t_accept_the_offer = {3, os.clock(), player_id}
								end

								table.remove(procedures_performed, index)
								if #procedures_performed == 0 then destroy_assistant_thread("procedures_performed") end
							else
								chat(string.format("Доктор {HEX}%s{} снова можете провести для Вас процедуру {HEX}%s{}.", string.gsub(value["nickname"], "_", " "), value["procedure"]))
								table.remove(procedures_performed, index)
								if #procedures_performed == 0 then destroy_assistant_thread("procedures_performed") end
							end
						end
					end
				end
			end

			if assistant_threads["normal_speedometer_update"] then
				if configuration["MAIN"]["settings"]["normal_speedometer_update"] then
					if isCharSittingInAnyCar(playerPed) then 
						if not t_smart_vehicle["speedometr_id"] or not sampTextdrawIsExists(t_smart_vehicle["speedometr_id"]) then
							for textdraw_id = 0, 3000 do
								if sampTextdrawIsExists(textdraw_id) then
									if string.match(sampTextdrawGetString(textdraw_id), "Fuel") then
										t_smart_vehicle["speedometr_id"] = textdraw_id
										break
									end
								end
							end
						else
							local vehicle_handle = storeCarCharIsInNoSave(playerPed)
							local vehicle_speed = getCarSpeed(vehicle_handle) * 2.02
							local textdraw_text = sampTextdrawGetString(t_smart_vehicle["speedometr_id"])
							sampTextdrawSetString(t_smart_vehicle["speedometr_id"], string.gsub(textdraw_text, "%d+_km/h", string.format("%d_km/h", vehicle_speed)))

							if configuration["MAIN"]["settings"]["low_fuel_level_notification"] then
								if not t_smart_vehicle["fuel"]["last_update"] then
									t_smart_vehicle["fuel"]["last_update"] = 0
								else
									if os.clock() - t_smart_vehicle["fuel"]["last_update"] > 5 then
										if string.match(textdraw_text, "Fuel_(%d+)") then
											local vehicle_fuel = tonumber(string.match(textdraw_text, "Fuel_(%d+)"))
											if vehicle_fuel and vehicle_fuel < 30 then
												if not t_smart_vehicle["fuel"]["last_notification"] then
													t_smart_vehicle["fuel"]["last_notification"] = 0
												else
													if os.clock() - t_smart_vehicle["fuel"]["last_notification"] > 180 then
														chat("Уровень топлива в вашем транспортом средстве {HEX}менее 30 литров{}.")
														chat("Чтобы найти ближайщую АЗС используйте команду {HEX}/fuel{}.")
														t_smart_vehicle["fuel"]["last_notification"] = os.clock()
													end
												end
											end
										end t_smart_vehicle["fuel"]["last_update"] = os.clock()
									end
								end
							end
						end
					end
				end
			end

			if assistant_threads["fast_interaction"] then
				if not global_samp_cursor_status then 
					if not isKeyDown(VK_RBUTTON) then
						if t_entity_marker[1] then 
						    removeBlip(t_entity_marker[1]) 
						    t_entity_marker = { false, false }
						end
					end
				else
					if not t_mimgui_render["quick_menu"]["state"] then
						if configuration["MAIN"]["settings"]["fast_interaction"] then
							local sx, sy = getCursorPos()
							local w, h = getScreenResolution()
							if (sx > 0 and sy > 0 and sx < w and sy < h) then
								local cursor_x, cursor_y, cursor_z = convertScreenCoordsToWorld3D(sx, sy, 700.0)
								local camera_x, camera_y, camera_z = getActiveCameraCoordinates()
								local result, colpoint = processLineOfSight(camera_x, camera_y, camera_z, cursor_x, cursor_y, cursor_z, true, true, true, true, true, true, true)
								if result then
									local px, py = convert3DCoordsToScreen(colpoint["pos"][1], colpoint["pos"][2], colpoint["pos"][3])
									local px = px + 15
									local py = py - 15

									if t_entity_marker[2] then
										if t_entity_marker[2] ~= colpoint["entity"] then
											removeBlip(t_entity_marker[1])
										    t_entity_marker = { false, false }
										end
									end

									if colpoint["entityType"] == 3 then
										local distance = getDistanceBetweenCoords3d(x, y, z, colpoint["pos"][1], colpoint["pos"][2], colpoint["pos"][3])
										if distance < 15 then
											local player_handle = getCharPointerHandle(colpoint["entity"])
											local result, player_id = sampGetPlayerIdByCharHandle(player_handle)
											if result then
												local player_nickname = sampGetPlayerNickname(player_id)
												renderFontDrawText(font, string.format("Для взаимодействия нажмите %sLButton{ffffff}.", configuration["MAIN"]["settings"]["script_color"]), px, py, 0xCAFFFFFF)

												if configuration["USERS"]["content"][player_nickname] then
												    renderFontDrawText(font, string.format("Игрок %s%s{ffffff} (id %s)", configuration["USERS"]["content"][player_nickname]["color"], player_nickname, player_id), px, py + 10, 0xFFFFFFFF)
												else
												    renderFontDrawText(font, string.format("Игрок %s (id %s)", player_nickname, player_id), px, py + 10, 0xFFFFFFFF)
												end

												if not t_entity_marker[1] then 
												    t_entity_marker = { addBlipForChar(player_handle), colpoint["entity"] }
												    local color = configuration["MAIN"]["settings"]["timestamp_color"] .. "FF"
												   	changeBlipColour(t_entity_marker[1], color)
												end

												if wasKeyPressed(vkeys.VK_LBUTTON) then
												    create_quick_menu("char", { ["player_id"] = player_id, ["distance"] = distance })
												end 
											end
										end
									elseif colpoint["entityType"] == 2 then
										local distance = getDistanceBetweenCoords3d(x, y, z, colpoint["pos"][1], colpoint["pos"][2], colpoint["pos"][3])
										if distance < 55 then
											local vehicle_handle = getVehiclePointerHandle(colpoint["entity"])
											local result, vehicle_id = sampGetVehicleIdByCarHandle(vehicle_handle)
											if result then
											    local vehicle_model = getCarModel(vehicle_handle)
											    local normal_model = vehicle_model - 399
											    local vehicle_type = t_vehicle_type_name[t_vehicle_type[normal_model]]
											    local vehicle_name = t_vehicle_name[normal_model]

											   	renderFontDrawText(font, string.format("Для взаимодействия нажмите %sLButton{ffffff}.", configuration["MAIN"]["settings"]["script_color"]), px, py, 0xCAFFFFFF)
											    renderFontDrawText(font, string.format("%s %s (id %s, model %s):", vehicle_type, vehicle_name, vehicle_id, vehicle_model), px, py + 10, 0xFFFFFFFF)

											    if not t_entity_marker[1] then 
												    t_entity_marker = { addBlipForCar(vehicle_handle), colpoint["entity"] }
												    local color = configuration["MAIN"]["settings"]["timestamp_color"] .. "FF"
												     changeBlipColour(t_entity_marker[1], color)
												end

											    if wasKeyPressed(vkeys.VK_LBUTTON) then
											        create_quick_menu("vehicle", { ["vehicle_id"] = vehicle_id, ["normal_model"] = normal_model, ["vehicle_handle"] = vehicle_handle, ["distance"] = distance})
											    end
											end
										end
									else
										if t_entity_marker[1] then 
										    removeBlip(t_entity_marker[1]) 
										    t_entity_marker = { false, false }
										end
									end
								end
							end
						end
					end
				end
			end

			if assistant_threads["fast_interaction_2"] then
				if not isKeyDown(VK_RBUTTON) then 
					if not global_samp_cursor_status then 
						if t_entity_marker[1] then
							removeBlip(t_entity_marker[1]) 
							t_entity_marker = { false, false }
							targeting_vehicle = false
						end
					end
				else
					if not t_mimgui_render["quick_menu"]["state"] then
						if configuration["MAIN"]["settings"]["fast_interaction"] then
							if not isCharSittingInAnyCar(playerPed) then
								local player_weapon = getCurrentCharWeapon(playerPed)
								if player_weapon == 0 or player_weapon == 3 then
									local x1, y1, z1 = getActiveCameraCoordinates()
									local x2, y2, z2 = getActiveCameraPointAt()

									local angle = math.atan2(y2 - y1, x2 - x1)
									local radius = 5
									local vector = { ["x"] = x + radius * math.cos(angle), ["y"] = y + radius * math.sin(angle), ["z"] = z + radius * (z2 - z1) }

									local result, colpoint = processLineOfSight(x, y, z, vector["x"], vector["y"], vector["z"], true, true, false, true, true, true, true)

									if result then
										if t_entity_marker[2] then
											if t_entity_marker[2] ~= colpoint["entity"] then 
											    removeBlip(t_entity_marker[1])
											    t_entity_marker = { false, false }
											    targeting_vehicle = false
											end
										end 

										if colpoint["entityType"] == 2 then 
											local vehicle_handle = getVehiclePointerHandle(colpoint["entity"])
											local result, vehicle_id = sampGetVehicleIdByCarHandle(vehicle_handle)

											if not isCharInAnyPoliceVehicle(playerPed) then 
												if result then
													local vehicle_model = getCarModel(vehicle_handle)
													local normal_model = vehicle_model - 399
													local vehicle_type = t_vehicle_type_name[t_vehicle_type[normal_model]]
													local vehicle_name = t_vehicle_name[normal_model]
													local distance = getDistanceBetweenCoords3d(x, y, z, colpoint["pos"][1], colpoint["pos"][2], colpoint["pos"][3])
													local w, h = convert3DCoordsToScreen(colpoint["pos"][1], colpoint["pos"][2], colpoint["pos"][3])

													if player_weapon == 0 then
														targeting_vehicle = { ["vehicle_id"] = vehicle_id, ["normal_model"] = normal_model, ["vehicle_handle"] = vehicle_handle, ["distance"] = distance }

														renderFontDrawText(font, string.format("Для взаимодействия нажмите %sZ{ffffff}.", configuration["MAIN"]["settings"]["script_color"]), w, h, 0xCAFFFFFF)
														renderFontDrawText(font, string.format("%s %s (id %s, model %s)", vehicle_type, vehicle_name, vehicle_id, vehicle_model), w, h + 10, 0xFFFFFFFF)
													end

													if not t_entity_marker[1] then 
														t_entity_marker = { addBlipForCar(vehicle_handle), colpoint["entity"] }
														local color = configuration["MAIN"]["settings"]["timestamp_color"] .. "FF"
														changeBlipColour(t_entity_marker[1], color) 
													end

												else
													if t_entity_marker[1] then
														removeBlip(t_entity_marker[1]) 
														t_entity_marker = { false, false }
														targeting_vehicle = false
													end
												end
											end
										end
									end
								end
							end
						end 
					end
				end
			end

			if assistant_threads["static_time"] then
				if not t_static_time[3] then
					if math.fmod(math.ceil(os.clock()), 60) == 0 then
						t_static_time = { os.date("%H"), os.date("%M"), false }
					end
				end
				setTimeOfDay(t_static_time[1], t_static_time[2])
			end

			if assistant_threads["time_take_ads"] then
				if time_take_ads then
					if os.clock() - time_take_ads > delay_take_ads then
						if isKeyCheckAvailable() and not t_mimgui_render["editor_ads"]["state"] then
							sampSendChat("/edit")
							time_take_ads = os.clock()
						end
					end
				end
			end

			if assistant_threads["pause_test"] then 
				if pause_start then
					if not isPauseMenuActive() then
						local difference = os.clock() - pause_start[1]
						configuration["STATISTICS"]["afk_time"] = configuration["STATISTICS"]["afk_time"] + difference
						if not need_update_configuration then need_update_configuration = os.clock() end

						if difference > 5 then
							chat(string.format("Вы находились в AFK {HEX}%d{} %s.", difference, get_words_ending("секунда", difference))) 
						end

						if difference > 0.2 then
							pause_start = nil
							destroy_assistant_thread("pause_test")
						end
					end
				else
					chat("зачем живу")
					destroy_assistant_thread("pause_test")
				end
			end
		end
	end
end

function th_smart_suspects()
	local font = renderCreateFont("tahoma", 8, font_flag.BOLD + font_flag.SHADOW)

	local crimes_configuration = configuration["MAIN"]["quick_criminal_code"]

	local possible_crimes = {
		{ ["index"] = "attack_officer",  ["clock"] = 180, ["significance"] = 6, ["description"] = "Нападение на офицера" },
		{ ["index"] = "attack_civil",    ["clock"] = 180, ["significance"] = 5, ["description"] = "Нападение на гражданского" },
		{ ["index"] = "insubordination", ["clock"] = 300, ["significance"] = 4, ["description"] = "Неповиновение законным требованиям" },
		{ ["index"] = "escape",          ["clock"] = 300, ["significance"] = 3, ["description"] = "Избегание задержания, побег" },
		{ ["index"] = "non_payment",     ["clock"] = 120, ["significance"] = 2, ["description"] = "Отказ от уплаты штрафа" }
	}

	function preliminary_check_suspect(player_id, crimes, ignore_visual_contact, temporary)
		if not possible_crimes[crimes] then return false, 0 end -- проверка возможности добавления в список
		if not isPlayerConnected(player_id) then return false, 1 end -- проверка подключён ли игрок
		local getted, player_handle = sampGetCharHandleBySampPlayerId(player_id)
		local visual_contact = ignore_visual_contact

		local index = string.format("tq_%s", possible_crimes[crimes]["index"])
		if not configuration["MAIN"]["settings"][index] then return false, 5 end -- проверяем активен ли данный пункт быстрого розыска

		if not ignore_visual_contact then
			if not getted then return false, 2 end -- проверяем существует ли игрок в зоне стрима

			local user_x, user_y, user_z = getActiveCameraCoordinates()
			local player_x, player_y, player_z = getCharCoordinates(player_handle)
			local player_distance = getDistanceBetweenCoords3d(user_x, user_y, user_z, player_x, player_y, player_z)
			visual_contact = isCharOnScreen(player_handle) and not processLineOfSight(user_x, user_y, user_z, player_x, player_y, player_z, true, false, false, true, false, false, true, false)

			if player_distance > 40 and not visual_contact then return false, 3 end
		end

		local player_nickname = sampGetPlayerName(player_id)
		local player_found = false

		local stars = crimes_configuration[possible_crimes[crimes]["index"]]["stars"]
		local reason = u8:decode(crimes_configuration[possible_crimes[crimes]["index"]]["reason"])

		if #t_smart_suspects > 0 then -- пытаемся найти игрока в списках
			for index, value in ipairs(t_smart_suspects) do
				if value["suspect"] and value["suspect"]["tnickname"] == player_nickname then
					for key, violations in ipairs(value["alleged_violations"]) do
						if violations["stars"] == stars and violations["reason"] == reason then
							return false, 4
						end 
					end player_found = index
				end
			end

			if temporary and t_smart_suspects[1]["alleged_violations"][1]["temporary"] then
				table.remove(t_smart_suspects[1]["alleged_violations"], 1)
				if #t_smart_suspects[1]["alleged_violations"] == 0 then table.remove(t_smart_suspects, 1) player_found = nil end
			end
		end

		local violations_code = string.format("Статья %s%s{ffffff}, уровень розыска %s%s", configuration["MAIN"]["settings"]["script_color"], reason, configuration["MAIN"]["settings"]["script_color"], stars)

		local fix_description = renderGetFontDrawTextLength(font, possible_crimes[crimes]["description"])
		local fix_criminal = renderGetFontDrawTextLength(font, violations_code)

		local violations = {
			["code"]         = violations_code,
			["crimes"]       = crimes,
			["description"]  = possible_crimes[crimes]["description"],
			["significance"] = possible_crimes[crimes]["significance"],
			["stars"]        = stars,
			["reason"]       = reason,
			["fix"]          = ((fix_description > fix_criminal) and fix_description or fix_criminal) + 6,
			["clock"]        = os.clock(),
			["temporary"]    = temporary
		}

		if visual_contact or ignore_visual_contact then
			if player_found then
				local space = t_smart_suspects[player_found]
				table.insert(space["alleged_violations"], violations)
				table.remove(t_smart_suspects, player_found)
				table.insert(t_smart_suspects, 1, space)
				table.sort(t_smart_suspects[1]["alleged_violations"], function(a, b) return (a["significance"] > b["significance"]) end)
			else
				table.insert(t_smart_suspects, 1, {
					["suspect"] = {
						["nickname"]       = string.format("%s #%s", player_nickname, player_id),
						["tnickname"]      = player_nickname,
						["id"]             = player_id,
						["visual_contact"] = visual_contact,
						["color"]          = "0xFF" .. bit.tohex(sampGetPlayerColor(player_id), 6)
					},
					["alleged_violations"] = { violations }
				})
			end
		else
			table.insert(t_smart_suspects, 1, {
				["suspect"] = {
					["nickname"]       = string.format("Неизвестный #%d", os.clock()),
					["tnickname"]      = player_nickname,
					["id"]             = player_id,
					["visual_contact"] = visual_contact,
					["color"]          = "0xFF" .. bit.tohex(sampGetPlayerColor(player_id), 6)
				},
				["alleged_violations"] = { violations }
			})
		end

		return true, 1
	end

	while script_is_alive do wait(0)
		if #t_smart_suspects > 0 then
			local x, y = configuration["MAIN"]["settings"]["tq_interface_x"], configuration["MAIN"]["settings"]["tq_interface_y"]
			local mx, my = getCursorPos()

			for index, value in ipairs(t_smart_suspects) do
				if isPlayerConnected(value["suspect"]["id"]) then
					for key, violation in ipairs(value["alleged_violations"]) do
						if os.clock() - violation["clock"] < possible_crimes[violation["crimes"]]["clock"] then
							local hovered = global_samp_cursor_status and ((mx >= x and mx <= x + violation["fix"]) and (my >= y and my <= y + 40)) or false

							renderDrawBox(x, y, violation["fix"], 40, hovered and 0xAC212121 or 0xF0212121)
							renderDrawBox(x - 5, y + 2, 3, 36, value["suspect"]["visual_contact"] and value["suspect"]["color"] or 0xFFFFFFFF)
							renderFontDrawText(font, value["suspect"]["nickname"], x + 3, y + 2, 0xFFFFFFFF)
							renderFontDrawText(font, violation["code"], x + 3, y + 14, 0xFFFFFFFF)
							renderFontDrawText(font, violation["description"], x + 3, y + 26, 0xFFFFFFFF)

							if not value["suspect"]["visual_contact"] then
								local result, player_handle = sampGetCharHandleBySampPlayerId(value["suspect"]["id"])
								if result then
									local user_x, user_y, user_z = getActiveCameraCoordinates()
									local player_x, player_y, player_z = getCharCoordinates(player_handle)
									value["suspect"]["visual_contact"] = isCharOnScreen(player_handle) and not processLineOfSight(user_x, user_y, user_z, player_x, player_y, player_z, true, false, false, true, false, false, true, false)
									if value["suspect"]["visual_contact"] then
										value["suspect"]["nickname"] = string.format("%s #%s", value["suspect"]["tnickname"], value["suspect"]["id"])
									end
								else
									chat(string.format("Подозреваемый {HEX}%s{} был исключён из быстрого розыска. Причина: скрылся из зоны видимости.", value["suspect"]["nickname"]))
									table.remove(t_smart_suspects, index)
								end
							end

							if hovered then
								if wasKeyPressed(vkeys["VK_LBUTTON"]) then
									command_su(string.format("%s %s %s", value["suspect"]["id"], violation["stars"], violation["reason"]))
								elseif wasKeyPressed(vkeys["VK_RBUTTON"]) then
									chat(string.format("Подозреваемый {HEX}%s{} был исключён из быстрого розыска.", value["suspect"]["nickname"]))
									table.remove(t_smart_suspects[index]["alleged_violations"], key)
									if #t_smart_suspects[index]["alleged_violations"] == 0 then table.remove(t_smart_suspects, index) end
								end
							end

							y = y + 42
						else
							chat(string.format("Подозреваемый {HEX}%s{} был исключён из быстрого розыска. Причина: прошло допустимое время (%s).", value["suspect"]["nickname"], possible_crimes[violation["crimes"]]["clock"]))
							table.remove(t_smart_suspects[index]["alleged_violations"], key)
							if #t_smart_suspects[index]["alleged_violations"] == 0 then table.remove(t_smart_suspects, index) end
						end
					end
				else
					chat(string.format("Подозреваемый {HEX}%s{} был исключён из быстрого розыска. Причина: выход из игры.", value["suspect"]["nickname"]))
					table.remove(t_smart_suspects, index)
				end
			end
		end
	end
end

function th_role_play_weapons()
	print("[HfMIA DEBUG] th_role_play_weapons STARTED, thread = " .. tostring(lua_thread.create))
	local current_weapons = 0
	local waiting_weapons_hidden
	local waiting_taking_weapons
	local possibility_action
	local action_was_performed

	local function action_weapons(weapon, action)
		local index = t_role_play_weapons[weapon] and t_role_play_weapons[weapon]["index"] or nil
		if index then
			local action = configuration["MAIN"]["role_play_weapons"][index] and configuration["MAIN"]["role_play_weapons"][index][action]
			if action and action ~= "" then
				sampSendChat(string.format("/me %s", u8:decode(action)))
			end
		end
	end

	while script_is_alive do wait(0)
		if configuration["MAIN"]["settings"]["weapon_acting_out"] then
			if not isCurrentCharWeapon(playerPed, current_weapons) then
				if waiting_weapons_hidden ~= current_weapons then
					if action_was_performed then
						action_weapons(current_weapons, "remove")
						waiting_weapons_hidden = current_weapons
						action_was_performed = nil
					end
				end

				if not waiting_taking_weapons then
					waiting_taking_weapons = { getCurrentCharWeapon(playerPed), os.clock() }
				else
					if os.clock() - waiting_taking_weapons[2] > configuration["MAIN"]["settings"]["waiting_time_taking_weapons"] then
						if getCurrentCharWeapon(playerPed) == waiting_taking_weapons[1] then
							current_weapons = getCurrentCharWeapon(playerPed)
							if configuration["MAIN"]["settings"]["auto_weapon_acting_out"] then
								action_weapons(current_weapons, "take")
								action_was_performed = true
							else
								possibility_action = current_weapons
							end
						end waiting_taking_weapons = nil
					else
						if getCurrentCharWeapon(playerPed) ~= waiting_taking_weapons[1] then waiting_taking_weapons = nil end
					end
				end
			end

			if possibility_action then
				if isKeyDown(VK_RBUTTON) then
					if possibility_action == getCurrentCharWeapon(playerPed) then
						action_weapons(possibility_action, "take")
						action_was_performed = true
						possibility_action = nil
					end
				end
			end
		end
	end
	print("[HfMIA DEBUG] th_role_play_weapons ENDED")
end
-- !thread

-- callback
function command_mh()
	-- mimgui_window("main_menu")
	t_mimgui_render["main_menu"]["switch"]()
end

function command_r(text)
	if not string.match(text, "(%S+)") then chat_error("Введите необходимые параметры для /r [текст].") return end

	local mark = ""
	if patrol_status["mark"] then
		mark = string.format("%s-%s", patrol_status["mark"], patrol_status["number"])
	else
		local result, player_id = sampGetPlayerIdByCharHandle(playerPed)
		local player_nickname = sampGetPlayerName(player_id)
		local first_name, second_name = string.match(tostring(player_nickname), "(%S+)_(%S+)")
		mark = string.format("%s.%s", string.sub(first_name, 1, 1), second_name)
	end

	for index, value in ipairs(abbreviated_codes) do
		if text == value[1] then
			text = string.gsub(text, value[1], value[2])
			value[4]()
		end
	end

	local text = string.gsub(text, "$m", mark)
	local text = string.gsub(text, "$p", calculateZone())
	sampSendChat(string.format("/r %s %s", configuration["MAIN"]["information"]["rtag"], text))
end

function command_f(text)
	if not string.match(text, "(%S+)") then chat_error("Введите необходимые параметры для /f (1 или 2) [текст].") return end

	local is_radio_type
	if string.match(text, "^[1?2] (%S+)") then is_radio_type, text = string.match(text, "^(%d) (.+)") end

	local mark = ""
	if patrol_status["mark"] then
		mark = string.format("%s-%s", patrol_status["mark"], patrol_status["number"])
	else
		local result, player_id = sampGetPlayerIdByCharHandle(playerPed)
		local player_nickname = sampGetPlayerName(player_id)
		local first_name, second_name = string.match(tostring(player_nickname), "(%S+)_(%S+)")
		mark = string.format("%s.%s", string.sub(first_name, 1, 1), second_name)
	end

	for index, value in ipairs(abbreviated_codes) do
		if text == value[1] then
			text = string.gsub(text, value[1], value[2])
			value[4]()
		end
	end

	local text = string.gsub(text, "$m", mark)
	local text = string.gsub(text, "$p", calculateZone())
	sampSendChat(string.format("/f %s%s %s", (is_radio_type and string.format("%s ", is_radio_type) or ""), configuration["MAIN"]["information"]["ftag"], text))
end

function command_rn(text)
	if not string.match(text, "(%S+)") then chat_error("Введите необходимые параметры для /rn [текст].") return end
	sampSendChat(string.format("/r (( %s ))", text))
end

function command_fn(text)
	if not string.match(text, "(%S+)") then chat_error("Введите необходимые параметры для /fn (1 или 2) [текст].") return end
	local is_radio_type
	if string.match(text, "^[1?2] (%S+)") then is_radio_type, text = string.match(text, "^(%d) (.+)") end
	if is_radio_type then sampSendChat(string.format("/f %s (( %s ))", is_radio_type, text)) else sampSendChat(string.format("/f (( %s ))", text)) end
end

function command_rep(text)
	if not string.match(text, "(%S+)") then chat_error("Введите необходимые параметры для /rep [текст].") return end
	report_text = text
	sampSendChat("/mn")
end

function command_rtag()
	local text = "{e6e6fa}Код\t\t{00CC66}Маркировка{e6e6fa}, {FFCD00}местоположение{e6e6fa} и содержание."
	for index, value in ipairs(abbreviated_codes) do
		text = string.format("%s\n{FFCD00}%s{e6e6fa}\t\t%s", text, value[1], value[2])
	end
	local text = string.gsub(text, "%$m", "{00CC66}" .. sampGetMarkCharByVehicle(playerPed) .. "{e6e6fa}")
	local text = string.gsub(text, "%$p", string.format("{FFCD00}%s{e6e6fa}", calculateZone()))
	sampShowDialog(1005, "{FFCD00}Список радио-тэгов для рации", text, "Закрыть", "", 5)
end

function command_uk()
	if not configuration["DOCUMENTS"]["content"] or not configuration["DOCUMENTS"]["content"][1] then chat("Не удалось загрузить уголовный кодекс.") return end
	global_current_document = configuration["DOCUMENTS"]["content"][1]
	mimgui_window("regulatory_legal_act")
	viewing_documents = true
end

function command_ak()
	if not configuration["DOCUMENTS"]["content"] or not configuration["DOCUMENTS"]["content"][1] then chat("Не удалось загрузить административный кодекс.") return end
	global_current_document = configuration["DOCUMENTS"]["content"][2]
	mimgui_window("regulatory_legal_act")
	viewing_documents = true
end

function command_sw(id)
	if string.match(id, "(%d+)") then
		local id = string.match(id, "(%d+)")
		if tonumber(id) > 0 and tonumber(id) <= 45 then
			forceWeatherNow(id)
			chat("Вы изменили игровую погоду на {HEX}" .. id .. "{} ID.")
		else chat("ID погоды не должен быть больше 45 и меньше 1.") end
	else chat_error("Введите необходимые параметры для /sw [ид погоды].") end
end

function command_st(parametrs)
	if string.match(parametrs, "(%d+) (%d+)") then
		local hour, minute = string.match(parametrs, "(%d+) (%d+)")
		if tonumber(hour) >= 0 and tonumber(hour) <= 23 and tonumber(minute) >= 0 and tonumber(minute) < 60 then
			patch_samp_time_set(true)
			t_static_time = { hour, minute, true }
			chat("Вы изменили игровое время на {HEX}" .. hour .. "{} часов, {HEX}" .. minute .. "{} минут.")
		else
			patch_samp_time_set(false)
			t_static_time = { os.date("%H"), os.date("%M"), false }
			chat("Часы не должны быть больше 23 и меньше 0. Минуты не должны быть больше 59 и меньше 0.")
		end
	else
		if t_static_time[3] then
			t_static_time = { os.date("%H"), os.date("%M"), false }
			patch_samp_time_set(false)
			chat("Вы перешли к режиму {HEX}динамического обновления времени{}.")
		else
			chat_error("Введите необходимые параметры для /st [часы] [минуты].")
		end
	end
end

function command_sskin(parametrs)
	if string.match(parametrs, "(%d+) (%d+)") then
		local id, skin, state = string.match(parametrs, "(%d+) (%d+)")
		if isPlayerConnected(id) then
			if sampGetDistanceToPlayer(id) < 200 then
				local BS = raknetNewBitStream()
				raknetBitStreamWriteInt32(BS, id)
				raknetBitStreamWriteInt32(BS, skin)
				raknetEmulRpcReceiveBitStream(153, BS)
				raknetDeleteBitStream(BS)
				local name = string.gsub(sampGetPlayerName(id),"_"," ")
				chat("Вы установили визуальный скин ({HEX}" .. skin .. "{}) для игрока " .. name .. "[" .. id .. "].")
			else chat("Данный игрок находится слишком далеко от Вас.") end
		else chat("Данный игрок не подключён к серверу. Проверьте правильность введёного ID.") end
	elseif string.match(parametrs, "(%d+)") then
		local skin = string.match(parametrs, "(%d+)")
		local result, id = sampGetPlayerIdByCharHandle(playerPed)
		if result then
			local BS = raknetNewBitStream()
			raknetBitStreamWriteInt32(BS, id)
			raknetBitStreamWriteInt32(BS, skin)
			raknetEmulRpcReceiveBitStream(153, BS)
			raknetDeleteBitStream(BS)
			chat("На Вашего персонажа был установлен визуальный скин {HEX}" .. skin .. "{}.")
		else chat("Произошла ошибка при попытке выдачи скина.") end
	else chat_error("Введите необходимые параметры для /sskin [id игрока (необязательно)] [ид скина].") end
end

function command_history(parametrs)
	if tonumber(parametrs) then
		sampSendChat(string.format("/history %s", sampGetPlayerName(parametrs)))
	elseif string.match(parametrs, "(%S+)") then
		sampSendChat(string.format("/history %s", parametrs))
	else chat_error("Введите необходимые параметры для /history [id игрока или никнейм].") end
end

function command_lsms(text)
	if string.match(text, "(%S+)") then
		if last_sms_number then
			command_sms(string.format("%d %s", last_sms_number, text))
		else chat("Ранее вам никто не отправлял SMS-сообщения.") end
	else chat_error("Введите необходимые параметры для /lsms [текст].") end
end

function command_addbl(nickname)
	if string.match(nickname, "(%S+)") then
		if tonumber(nickname) then nickname = sampGetPlayerName(nickname) end
		if nickname then
			if not configuration["MAIN"]["blacklist"][nickname] then
				configuration["MAIN"]["blacklist"][nickname] = true
				if not need_update_configuration then need_update_configuration = os.clock() end
				chat(string.format("{HEX}%s{} был добавлен в чёрный список. Сообщения и звонки более не будут Вас беспокоить.", nickname))
			else chat("Данный игрок уже находится в чёрном списке.") end
		else chat("Данный игрок не подключён к серверу. Проверьте правильность введёного ID.") end
	else chat_error("Введите необходимые параметры для /addbl [никнейм или id игрока].") end
end

function command_delbl(nickname)
	if string.match(nickname, "(%S+)") then
		if tonumber(nickname) then nickname = sampGetPlayerName(nickname) end
		if nickname then
			if configuration["MAIN"]["blacklist"][nickname] then
				configuration["MAIN"]["blacklist"][nickname] = false
				if not need_update_configuration then need_update_configuration = os.clock() end
				chat(string.format("{HEX}%s{} был вынесен из чёрного списка.", nickname))
			else chat("Данный игрок не находится в чёрном списке.") end
		else chat("Данный игрок не подключён к серверу. Проверьте правильность введёного ID.") end
	else chat_error("Введите необходимые параметры для /delbl [никнейм или id игрока].") end
end

function command_users()
	chat("Данная команда более недоступна в связи с добавлением нового раздела в меню.")
end

function command_rkinfo()
	if not delay_between_deaths then chat("Информация станет доступна после первой смерти.") return end
	local alltime = configuration["MAIN"]["settings"]["delay_between_deaths"] * 60 - math.floor(os.clock() - delay_between_deaths[2])
	local minute = math.floor(alltime / 60)
	local second = math.fmod(alltime, 60)
	if alltime > 0 and alltime < configuration["MAIN"]["settings"]["delay_between_deaths"] * 60 then
		if tostring(calculateZone()) == tostring(delay_between_deaths[1]) then
			chat(string.format("[{ff5c33}WARN{}] Вы можете вернуться в район {ff5c33}%s{} через %s:%s ({HEX}%d{} сек).", delay_between_deaths[1], minute, second, alltime))
		else
			chat(string.format("Вы можете вернуться в район {ff5c33}%s{} через %s:%s ({HEX}%d{} сек).", delay_between_deaths[1], minute, second, alltime))
		end
	else chat(string.format("Время вышло и Вы {00cc99}можете{} вернуться в район %s.", delay_between_deaths[1])) end
end

function command_sms(parametrs)
	if string.match(parametrs, "(%d+)  (%S+)") then
		local number, text = string.match(parametrs, "(%d+)  (.+)")
		if text and string.len(text) > 60 then
			local result = string_pairs(text, 60)
			local l1, l2 = result[1], result[2]
			sampSendChat(string.format("/sms %d %s ..", number, l1))
			sampSendChat(string.format("/sms %d .. %s", number, l2))
		else
			sampSendChat(string.format("/sms %d %s", number, text))
		end
	elseif string.match(parametrs, "(%d+) (%S+)") then
		local number, text = string.match(parametrs, "(%d+) (.+)")

		if string.len(number) < 4 and string.sub(text, 1, 1) ~= " " then
			if isPlayerConnected(number) then
				local name = sampGetPlayerName(number)
				if configuration["DATABASE"]["player"][name] and configuration["DATABASE"]["player"][name]["telephone"] then
					number = configuration["DATABASE"]["player"][name]["telephone"]
				else
					chat("Номер игрока не найден в базе данных.")
					return
				end
			end
		end

		if text and string.len(text) > 60 then
			local result = string_pairs(text, 60)
			local l1, l2 = result[1], result[2]
			sampSendChat(string.format("/sms %d %s ..", number, l1))
			sampSendChat(string.format("/sms %d .. %s", number, l2))
		else
			sampSendChat(string.format("/sms %d %s", number, text))
		end
	else chat_error("Введите необходимые параметры для /sms ([номер телефона] или [id игрока]) [сообщение].") end
end

function command_rec(parametrs)
	if global_reconnect_status then
		chat("Невозможно переподключится к другому серверу пока идёт переподключение.")
		return
	end

	if string.match(parametrs, "(%d+)") then
		local delay = tonumber(parametrs)
		if delay >= 0 and delay <= 60 then
			reconnect(delay)
		else chat("Задержка между переподключениями не должна быть менее 0 и более 60 секунд.") end
	elseif parametrs == "f" then
		fast_reconnect = true
		for index = 1, 20 do sampSendChat("/pay 1005 0") end
	else chat_error("Введите необходимые параметры для /rec [задержка].") end
end

function command_recn(parametrs)
	if global_reconnect_status then
		chat("Невозможно переподключится к другому серверу пока идёт переподключение.")
		return
	end

	if string.match(parametrs, "(%d+) (%S+)") then
		local delay, name = string.match(parametrs, "(%d+) (.+)")
		local delay = tonumber(delay)
		if delay >= 0 and delay <= 60 then
			sampSetLocalPlayerName(name)
			reconnect(delay)
		else
			chat("Задержка между переподключениями не должна быть менее 0 и более 60 секунд.")
		end
	else
		chat_error("Введите необходимые параметры для /recn [задержка] [никнейм].")
	end
end

function command_recd(parametrs)
	if global_reconnect_status then
		chat("Невозможно переподключится к другому серверу пока идёт переподключение.")
		return
	end

	if string.match(parametrs, "(%S+) (%S+)") then
		local ip, name = string.match(parametrs, "(%S+) (%S+)")
		if string.match(ip, "(%S+):(%d+)") then
			sampSetLocalPlayerName(name)
			reconnect(1, ip)
		else
			chat("IP-адресс сервера должен быть в формате {HEX}IP:PORT{} (например: {HEX}5.254.104.132:7777{}).")
		end
	elseif string.match(parametrs, "(%S+)") then
		local ip = parametrs
		if string.match(ip, "(%S+):(%d+)") then
			sampSetLocalPlayerName(name)
			reconnect(1, ip)
		else
			chat("IP-адресс сервера должен быть в формате {HEX}IP:PORT{} (например: {HEX}5.254.104.132:7777{}).")
		end
	else
		chat_error("Введите необходимые параметры для /recd [IP-адресс сервера] [никнейм (необязательно)].")
	end
end

function command_strobes()
	b_stroboscopes = not b_stroboscopes
	lua_thread.create(t_stroboscopes)
end

function command_savepass()
	if entered_to_save_password then
		local ip_adress = entered_to_save_password["ip_adress"]
		local nickname = entered_to_save_password["nickname"]
		local password = entered_to_save_password["password"]

		if not configuration["MANAGER"][ip_adress] then configuration["MANAGER"][ip_adress] = {} end
		if not configuration["MANAGER"][ip_adress][nickname] then configuration["MANAGER"][ip_adress][nickname] = {} end

		configuration["MANAGER"][ip_adress][nickname] = {
			password = password,
			gauth = configuration["MANAGER"][ip_adress][nickname]["gauth"]
		}

		if not need_update_configuration then need_update_configuration = os.clock() end
		chat("Вы успешено сохранили новые данные в менеджере аккаунтов.")
	else chat("В данный момент Вы не можете обновить данные в менеджере аккаунтов. Ошибка #1.") end
end

function command_infred()
	if not night_vision then
		infrared_vision = not infrared_vision
		setInfraredVision(infrared_vision)
		chat("Вы изменили состояние отображения эффекта {HEX}тепловизора{}.")
	else chat("Отключите отображение эффекта {HEX}прибора ночного видения{}.") end
end

function command_nigvis()
	if not infrared_vision then
		night_vision = not night_vision
		setNightVision(night_vision)
		chat("Вы изменили состояние отображения эффекта {HEX}прибора ночного виденья{}.")
	else chat("Отключите отображение эффекта {HEX}тепловизора{}.") end
end

function command_call(parametrs)
	if string.match(parametrs, "(%d+) ") then
		local number = string.match(parametrs, "(%d+) ")
		if isPlayerConnected(number) then
			local name = sampGetPlayerName(number)
			if configuration["DATABASE"]["player"][name] and configuration["DATABASE"]["player"][name]["telephone"] then
				sampSendChat(string.format("/c %s", configuration["DATABASE"]["player"][name]["telephone"]))
			else
				chat("Номер игрока не найден в базе данных.")
				return
			end
		else chat("Данный игрок не подключён к серверу. Проверьте правильность введёного ID.") end
	elseif string.match(parametrs, "(%d+)") then
		local number = parametrs
		sampSendChat(string.format("/c %s", number))
	else sampSendChat("/c") end
end

function command_pull(id)
	if string.match(id, "(%d+)") then
		if isPlayerConnected(id) then
			if sampGetDistanceToPlayer(id) < 5 then
				local result, ped = sampGetCharHandleBySampPlayerId(id)
				if result then
					if isCharSittingInAnyCar(ped) then
						local model = getCarModel(storeCarCharIsInNoSave(ped)) - 399
						local male = configuration["MAIN"]["information"]["sex"] and "female" or "male"
						local acting = configuration["CUSTOM"]["SYSTEM"][male]["pull"]["variations"]
						lua_thread.create(function()
							if t_vehicle_type[model] == 2 or t_vehicle_type[model] == 9 then
								local acting = acting[1]
								final_command_handler(acting, {id})
							else
								local acting = acting[2]
								final_command_handler(acting, {id})
							end
						end)
					else chat("Данный игрок не находится в транспорте.") end
				end
			else chat("Данный игрок находится слишком далеко от Вас.") end
		else chat("Данный игрок не подключён к серверу, проверьте правильность введёного ID.") end
	else chat_error("Введите необходимые параметры для /pull [id игрока].") end
end

function command_cuff(id)
	if string.match(id, "(%d+)") then
		if isPlayerConnected(id) then
			if sampGetDistanceToPlayer(id) < 3 then
				lua_thread.create(function()
					local male = configuration["MAIN"]["information"]["sex"] and "female" or "male"
					local acting = configuration["CUSTOM"]["SYSTEM"][male]["cuff"]["variations"]
					local acting = acting[math.random(1, #acting)]
					final_command_handler(acting, {id})
				end)
			else chat("Данный игрок находится слишком далеко от Вас.") end
		else chat("Данный игрок не подключён к серверу, проверьте правильность введёного ID.") end
	else chat_error("Введите необходимые параметры для /cuff [id игрока].") end
end

function command_uncuff(id)
	if string.match(id, "(%d+)") then
		if isPlayerConnected(id) then
			if sampGetDistanceToPlayer(id) < 3 then
				lua_thread.create(function()
					local male = configuration["MAIN"]["information"]["sex"] and "female" or "male"
					local acting = configuration["CUSTOM"]["SYSTEM"][male]["uncuff"]["variations"]
					local acting = acting[math.random(1, #acting)]
					final_command_handler(acting, {id})
				end)
			else chat("Данный игрок находится слишком далеко от Вас.") end
		else chat("Данный игрок не подключён к серверу, проверьте правильность введёного ID.") end
	else chat_error("Введите необходимые параметры для /uncuff [id игрока].") end
end

function command_arrest(id)
	if string.match(id, "(%d+)") then
		if isPlayerConnected(id) then
			if sampGetDistanceToPlayer(id) < 3 then
				lua_thread.create(function()
					local male = configuration["MAIN"]["information"]["sex"] and "female" or "male"
					local acting = configuration["CUSTOM"]["SYSTEM"][male]["arrest"]["variations"]
					local acting = acting[math.random(1, #acting)]
					final_command_handler(acting, {id})
				end)
			else chat("Данный игрок находится слишком далеко от Вас.") end
		else chat("Данный игрок не подключён к серверу, проверьте правильность введёного ID.") end
	else chat_error("Введите необходимые параметры для /arrest [id игрока].") end
end

function command_su(parametrs)
	if string.match(parametrs, "(%d+) (%d+) (%S+)") then
		local id, stars, reason = string.match(parametrs, "(%d+) (%d+) (.+)")
		if isPlayerConnected(id) then
			if sampGetDistanceToPlayer(id) < 66 then
				lua_thread.create(function()
					local male = configuration["MAIN"]["information"]["sex"] and "female" or "male"
					local acting = configuration["CUSTOM"]["SYSTEM"][male]["su"]["variations"]
					local acting = acting[math.random(1, #acting)]
					final_command_handler(acting, {id, stars, reason})
				end)
			else chat("Данный игрок находится слишком далеко от Вас.") end
		else chat("Данный игрок не подключён к серверу, проверьте правильность введёного ID.") end
	elseif string.match(parametrs, "(%d+)") then
		local id = string.match(parametrs, "(%d+)")
		if isPlayerConnected(id) then
			if sampGetDistanceToPlayer(id) < 66 then
				if not configuration["DOCUMENTS"]["content"] or not configuration["DOCUMENTS"]["content"][1] then chat("Не удалось загрузить уголовный кодекс.") return end
				global_current_document = configuration["DOCUMENTS"]["content"][1]
				smart_suspect_id = id
				viewing_documents = false
				mimgui_window("regulatory_legal_act", true)
			else chat("Данный игрок находится слишком далеко от Вас.") end
		else chat("Данный игрок не подключён к серверу, проверьте правильность введёного ID.") end
	else chat_error("Введите необходимые параметры для /su [id игрока] [кол-во звёзд] [причина].") end
end

function command_skip(id)
	if string.match(id, "(%d+)") then
		if isPlayerConnected(id) then
			if sampGetDistanceToPlayer(id) < 3 then
				lua_thread.create(function()
					local male = configuration["MAIN"]["information"]["sex"] and "female" or "male"
					local acting = configuration["CUSTOM"]["SYSTEM"][male]["skip"]["variations"]
					local acting = acting[math.random(1, #acting)]
					final_command_handler(acting, {id})
				end)
			else chat("Данный игрок находится слишком далеко от Вас.") end
		else chat("Данный игрок не подключён к серверу, проверьте правильность введёного ID.") end
	else chat_error("Введите необходимые параметры для /skip [id игрока].") end
end

function command_clear(parametrs)
	if string.match(parametrs, "(%d+) (%S+)") then
		local id, reason = string.match(parametrs, "(%d+) (.+)")
		if isPlayerConnected(id) then
			if sampGetDistanceToPlayer(id) < 5 then
				lua_thread.create(function()
					local male = configuration["MAIN"]["information"]["sex"] and "female" or "male"
					local acting = configuration["CUSTOM"]["SYSTEM"][male]["clear"]["variations"]
					local acting = acting[math.random(1, #acting)]
					final_command_handler(acting, {id, reason})
				end)
			else chat("Данный игрок находится слишком далеко от Вас.") end
		else chat("Данный игрок не подключён к серверу, проверьте правильность введёного ID.") end
	else chat_error("Введите необходимые параметры для /clear [id игрока] [причина].") end
end

function command_hold(id)
	if string.match(id, "(%d+)") then
		if isPlayerConnected(id) then
			if sampGetDistanceToPlayer(id) < 3 then
				lua_thread.create(function()
					local male = configuration["MAIN"]["information"]["sex"] and "female" or "male"
					local acting = configuration["CUSTOM"]["SYSTEM"][male]["hold"]["variations"]
					local acting = acting[math.random(1, #acting)]
					final_command_handler(acting, {id})
				end)
			else chat("Данный игрок находится слишком далеко от Вас.") end
		else chat("Данный игрок не подключён к серверу, проверьте правильность введёного ID.") end
	else chat_error("Введите необходимые параметры для /hold [id игрока].") end
end

function command_ticket(parametrs)
	if string.match(parametrs, "(%d+) (%d+) (%S+)") then
		local id, money, reason = string.match(parametrs, "(%d+) (%d+) (.+)")
		if isPlayerConnected(id) then
			if sampGetDistanceToPlayer(id) < 5 then
				lua_thread.create(function()
					local male = configuration["MAIN"]["information"]["sex"] and "female" or "male"
					local acting = configuration["CUSTOM"]["SYSTEM"][male]["ticket"]["variations"]
					local acting = acting[math.random(1, #acting)]
					final_command_handler(acting, {id, money, reason})
				end)
			else chat("Данный игрок находится слишком далеко от Вас.") end
		else chat("Данный игрок не подключён к серверу, проверьте правильность введёного ID.") end
	elseif string.match(parametrs, "(%d+)") then
		local id = string.match(parametrs, "(%d+)")
		if isPlayerConnected(id) then
			if sampGetDistanceToPlayer(id) < 5 then
				if not configuration["DOCUMENTS"]["content"] or not configuration["DOCUMENTS"]["content"][2] then chat("Не удалось загрузить административный кодекс.") return end
				global_current_document = configuration["DOCUMENTS"]["content"][2]
				smart_suspect_id = id
				viewing_documents = false
				mimgui_window("regulatory_legal_act", true)
			else chat("Данный игрок находится слишком далеко от Вас.") end
		else chat("Данный игрок не подключён к серверу, проверьте правильность введёного ID.") end
	else chat_error("Введите необходимые параметры для /ticket [id игрока] [сумма] [причина].") end
end

function command_takelic(parametrs)
	if string.match(parametrs, "(%d+) (%S+)") then
		local id, reason = string.match(parametrs, "(%d+) (.+)")
		if isPlayerConnected(id) then
			if sampGetDistanceToPlayer(id) < 10 then
				lua_thread.create(function()
					local male = configuration["MAIN"]["information"]["sex"] and "female" or "male"
					local acting = configuration["CUSTOM"]["SYSTEM"][male]["takelic"]["variations"]
					local acting = acting[math.random(1, #acting)]
					final_command_handler(acting, {id, reason})
				end)
			else chat("Данный игрок находится слишком далеко от Вас.") end
		else chat("Данный игрок не подключён к серверу, проверьте правильность введёного ID.") end
	else chat_error("Введите необходимые параметры для /takelic [id игрока] [причина].") end
end

function command_putpl(id)
	if string.match(id, "(%d+)") then
		if isPlayerConnected(id) then
			if sampGetDistanceToPlayer(id) < 5 then
				lua_thread.create(function()
					local male = configuration["MAIN"]["information"]["sex"] and "female" or "male"
					local acting = configuration["CUSTOM"]["SYSTEM"][male]["putpl"]["variations"]
					local acting = acting[math.random(1, #acting)]
					final_command_handler(acting, {id})
				end)
			else chat("Данный игрок находится слишком далеко от Вас.") end
		else chat("Данный игрок не подключён к серверу, проверьте правильность введёного ID.") end
	else chat_error("Введите необходимые параметры для /putpl [id игрока].") end
end

function command_rights()
	lua_thread.create(function()
		local male = configuration["MAIN"]["information"]["sex"] and "female" or "male"
		local acting = configuration["CUSTOM"]["SYSTEM"][male]["rights"]["variations"]
		local acting = acting[math.random(1, #acting)]
		final_command_handler(acting, {id})
	end)
end

function command_search(id)
	if string.match(id, "(%d+)") then
		if isPlayerConnected(id) then
			if sampGetDistanceToPlayer(id) < 3 then
				lua_thread.create(function()
					local male = configuration["MAIN"]["information"]["sex"] and "female" or "male"
					local acting = configuration["CUSTOM"]["SYSTEM"][male]["search"]["variations"]
					local acting = acting[math.random(1, #acting)]
					final_command_handler(acting, {id})
				end)
			else chat("Данный игрок находится слишком далеко от Вас.") end
		else chat("Данный игрок не подключён к серверу, проверьте правильность введёного ID.") end
	else chat_error("Введите необходимые параметры для /search [id игрока].") end
end

function command_hack(id)
	if string.match(id, "(%d+)") then
		lua_thread.create(function()
			local male = configuration["MAIN"]["information"]["sex"] and "female" or "male"
			local acting = configuration["CUSTOM"]["SYSTEM"][male]["hack"]["variations"]
			local acting = acting[math.random(1, #acting)]
			final_command_handler(acting, {id})
		end)
	else chat_error("Введите необходимые параметры для /hack [ид дома].") end
end

function command_invite(parametrs)
	if string.match(parametrs, "(%d+) (%d+)") then
		local id, rang = string.match(parametrs, "(%d+) (%d+)")
		if isPlayerConnected(id) then
			if sampGetDistanceToPlayer(id) < 5 then
				lua_thread.create(function()
					local male = configuration["MAIN"]["information"]["sex"] and "female" or "male"
					local acting = configuration["CUSTOM"]["SYSTEM"][male]["invite"]["variations"]
					local acting = acting[math.random(1, #acting)]
					final_command_handler(acting, {id})
					invite_player_id, invite_rang = id, rang
				end)
			else chat("Данный игрок находится слишком далеко от Вас.") end
		else chat("Данный игрок не подключён к серверу, проверьте правильность введёного ID.") end
	else chat_error("Введите необходимые параметры для /invite [id игрока] [ранг].") end
end

function command_uninvite(parametrs)
	if string.match(parametrs, "(%d+) (%S+)") then
		local id, reason = string.match(parametrs, "(%d+) (.+)")
		if isPlayerConnected(id) then
			lua_thread.create(function()
				local male = configuration["MAIN"]["information"]["sex"] and "female" or "male"
				local acting = configuration["CUSTOM"]["SYSTEM"][male]["uninvite"]["variations"]
				local acting = acting[math.random(1, #acting)]
				final_command_handler(acting, {id, reason})
			end)
		else chat("Данный игрок не подключён к серверу, проверьте правильность введёного ID.") end
	else chat_error("Введите необходимые параметры для /uninvite [id игрока] [причина].") end
end

function command_rang(parametrs)
	if string.match(parametrs, "(%d+) [+?-]") then
		local id, rang = string.match(parametrs, "(%d+) (.+)")
		if isPlayerConnected(id) then
			lua_thread.create(function()
				local male = configuration["MAIN"]["information"]["sex"] and "female" or "male"
				local acting = configuration["CUSTOM"]["SYSTEM"][male]["rang"]["variations"]
				local acting = acting[math.random(1, #acting)]
				final_command_handler(acting, {id, rang})
			end)
		else chat("Данный игрок не подключён к серверу, проверьте правильность введёного ID.") end
	else chat_error("Введите необходимые параметры для /rang [id игрока] [+ или -].") end
end

function command_changeskin(id)
	if string.match(id, "(%d+)") then
		if isPlayerConnected(id) then
			if sampGetDistanceToPlayer(id) < 3 then
				lua_thread.create(function()
					local male = configuration["MAIN"]["information"]["sex"] and "female" or "male"
					local acting = configuration["CUSTOM"]["SYSTEM"][male]["changeskin"]["variations"]
					local acting = acting[math.random(1, #acting)]
					final_command_handler(acting, {id})
				end)
			else chat("Данный игрок находится слишком далеко от Вас.") end
		else chat("Данный игрок не подключён к серверу, проверьте правильность введёного ID.") end
	else chat_error("Введите необходимые параметры для /changeskin [id игрока].") end
end

function command_ud()
	lua_thread.create(function()
		local male = configuration["MAIN"]["information"]["sex"] and "female" or "male"
		local acting = configuration["CUSTOM"]["SYSTEM"][male]["ud"]["variations"]
		local acting = acting[math.random(1, #acting)]
		final_command_handler(acting, {})
	end)
end

function command_pas()
	lua_thread.create(function()
		local male = configuration["MAIN"]["information"]["sex"] and "female" or "male"
		local acting = configuration["CUSTOM"]["SYSTEM"][male]["pas"]["variations"]
		local acting = acting[math.random(1, #acting)]
		final_command_handler(acting, {})
		if configuration["MAIN"]["settings"]["passport_check"] then passport_check = true end
	end)
end

function command_megafon(player_id, vehicle_id)
	lua_thread.create(function()
		if not player_id or vehicle_id then
			player_id, vehicle_id = sampGetNearestDriver()
		end

		if player_id then
			local normal_vehicle_id = vehicle_id - 399
			local nickname = sampGetPlayerName(player_id)
			sampSendChat(string.format("/m Внимание, водитель %s %s с госномером #SA-%s.", tf_vehicle_type_name[1][t_vehicle_type[normal_vehicle_id]], t_vehicle_name[normal_vehicle_id], player_id))
			wait(1000)
			sampSendChat("/m Немедленно остановите ваше транспортное средство и прижмитесь к обочине.")
			if t_last_requirement["nickname"] == nickname then
				wait(1000)
				sampSendChat("/m В случае неподчинения будет открыт огонь по колёсам и обшивке транспорта.")
				if configuration["MAIN"]["settings"]["chase_message"] then
					wait(1000)
					if global_radio == "r" then
						command_r(string.format("Говорит $m, веду погоню за %s %s с госномером #SA-%s. Находимся в районе %s, CODE 3, недоступен.", tf_vehicle_type_name[2][t_vehicle_type[normal_vehicle_id]], t_vehicle_name[normal_vehicle_id], player_id, calculateZone()))
					else
						command_f(string.format("Говорит $m, веду погоню за %s %s с госномером #SA-%s. Находимся в районе %s, CODE 3, недоступен.", tf_vehicle_type_name[2][t_vehicle_type[normal_vehicle_id]], t_vehicle_name[normal_vehicle_id], player_id, calculateZone()))
					end
					patrol_status["status"] = 3
				end
			end t_last_requirement = {nickname = nickname, player_id = player_id}

			wait(250)
			preliminary_check_suspect(player_id, 3, true)
		else sampSendChat("/m Немедленно остановите ваше транспортное средство и прижмитесь к обочине.") end
	end)
end

function command_drop_all()
	drop_all = true
	sampSendChat("/drop")
end

function command_patrol()
	mimgui_window("setting_patrol")
end

function command_fuel()
	sampSendChat("/fuel")
end

function command_speller(text)
	if string.match(text, "(%S+)") then
		local result = speller(text)
		if result then
			if #result > 0 then
				local speller_result = {}
				for k, v in pairs(result) do
					chat(string.format("%s. Ошибка в слове '{HEX}%s{}', правильно: '{HEX}%s{}'.", k, u8:decode(v["word"]), u8:decode(v["s"][1])))
					table.insert(speller_result, {v["word"], v["s"][1]})
				end return speller_result
			else chat("Всё написано верно.") end
		else chat("Не удалось получить ответ на запрос.") end
	else chat_error("Введите необходимые параметры для /speller [слово или сочетание слов].") end
end

function command_goverment_news(parametrs)
	local index1, index2
	if string.match(parametrs, "(%d+) (%d+)") then index1, index2 = string.match(parametrs, "(%d+) (%d+)") end
	if index1 and index2 then
		index1, index2 = tonumber(index1), tonumber(index2)
		if index2 - index1 < 0 or index2 - index1 > 10 then
			chat("Невозможно вывести заданный вами диапозон.")
			return
		end
	else
		index1 = #goverment_news - 10
		index2 = #goverment_news
	end

	local output = "{ffffff}Список пуст."

	for k = index2, index1, -1 do
		if goverment_news[k] then
			local value = goverment_news[k]["value"]
			output = string.format("%s\n\n#%s Новость от %s:", output, k, goverment_news[k]["nickname"])

			for i, v in pairs(value) do
				output = string.format("%s\n[{%s}%s{ffffff}] %s", output, goverment_news[k]["ok"] and "ff5c33" or "00cc99", os.date("%H:%M:%S", goverment_news[k]["time"]), v)
			end

			if k > 1 then
				local last_news, current_news = goverment_news[k - 1], goverment_news[k]
				local difference = (current_news["clock"] - last_news["clock"]) / 60

				if #last_news["value"] == 3 then
					if #current_news["value"] == 1 then
						if difference < 1 then
							output = string.format("%s\n{ff5c33}** {ffffff}Нарушен интервал (%0.2f из 1) между строками (3-1).", output, difference)
						end
					else
						if difference < 5 then
							output = string.format("%s\n{ff5c33}** {ffffff}Нарушен интервал (%0.2f из 5) между строками (3-3).", output, difference)
						end
					end
				else
					if difference < 3 then
						output = string.format("%s\n{ff5c33}** {ffffff}Нарушен интервал (%0.2f из 3) между строками (1-N).", output, difference)
					end
				end
			end

			if #value ~= 1 and #value ~= 3 then
				output = string.format("%s\n{ff5c33}** {ffffff}Отправлено недопустимое количество строк.", output)
			end
		end
	end

	output = string.gsub(output, "{ffffff}Список пуст.\n\n", "{ffffff}")
	sampShowDialog(1, "{FFCD00}Последние гос. новости", output, "Закрыть", "", 0)

	--[[local max_index = #goverment_news
	if max_index > 0 then
		local difference = (os.clock() - goverment_news[max_index]["clock"]) / 60

		if #goverment_news[max_index]["value"] == 3 then
			local one = difference > 1 and "{00cc99}возможна" or "{ff5c33}невозможна"
			local three =  difference > 5 and "{00cc99}возможна" or "{ff5c33}невозможна"

			chat("Последняя новость содержала 3 строки.")
			chat(string.format("Отправка новости содержащей одну строку %s{}, трёх строк %s{}.", one, three))
		else
			local one = difference > 3 and "{00cc99}возможна" or "{ff5c33}невозможна"
			local three =  difference > 3 and "{00cc99}возможна" or "{ff5c33}невозможна"

			chat("Последняя новость содержала менее 3х строк.")
			chat(string.format("Отправка новости содержащей одну строку %s{}, трёх строк %s{}.", one, three))
		end
	end--]]
end

function command_helper_stats()
	local dialog = {
		{ ["title"] = "Разделы", ["onclick"] = function() end },
		{
			["title"] = "Основная информация",
			["submenu"] = {
				["title"] = "Раздел основной информации",
				{ ["title"] = "Параметр\tЗначение", ["onclick"] = function() end },
				{ ["title"] = string.format("Общее время нахождения в AFK\t{00cc99}%d{ffffff} сек.", configuration["STATISTICS"]["afk_time"]), ["onclick"] = function() end },
				{ ["title"] = string.format("Количество сообщений в чат\t{00cc99}%d{ffffff} сообщ.", configuration["STATISTICS"]["message"]), ["onclick"] = function() end },
				{ ["title"] = string.format("Количество использованных масок\t{00cc99}%d{ffffff} шт.", math.floor(configuration["STATISTICS"]["number_masks_used"])), ["onclick"] = function() end },
				{ ["title"] = string.format("Количество использованных аптечек\t{00cc99}%d{ffffff} шт.", math.floor(configuration["STATISTICS"]["time_using_aid_kits"] / 5.5)), ["onclick"] = function() end },
				{ ["title"] = string.format("Суммарное время использования масок\t{00cc99}%d{ffffff} сек.", math.floor(configuration["STATISTICS"]["time_using_mask"])), ["onclick"] = function() end },
				{ ["title"] = string.format("Суммарное время использования аптечек\t{00cc99}%d{ffffff} сек.", math.floor(configuration["STATISTICS"]["time_using_aid_kits"])), ["onclick"] = function() end }
			}
		},
		{
			["title"] = "Правоохранительная деятельность",
			["submenu"] = {
				["title"] = "Раздел правоохранительной деятельности",
				{ ["title"] = "Параметр\tЗначение", ["onclick"] = function() end },
				{ ["title"] = string.format("Подозреваемые, оглушённые при помощи тэйзера\t{00cc99}%s{ffffff} чел.", configuration["STATISTICS"]["police"]["taser"]), ["onclick"] = function() end },
				{ ["title"] = string.format("Подозреваемые, оглушённые при помощи дубинки\t{00cc99}%s{ffffff} чел.", configuration["STATISTICS"]["police"]["baton"]), ["onclick"] = function() end },
				{ ["title"] = string.format("Подозреваемые, скованные наручниками\t{00cc99}%s{ffffff} чел.", configuration["STATISTICS"]["police"]["cuff"]), ["onclick"] = function() end },
				{ ["title"] = string.format("Наручники сняты с подозреваемых\t{00cc99}%s{ffffff} раз(-а)", configuration["STATISTICS"]["police"]["uncuff"]), ["onclick"] = function() end },
				{ ["title"] = string.format("Подозреваемые, усаженные в машину\t{00cc99}%s{ffffff} чел.", configuration["STATISTICS"]["police"]["putpl"]), ["onclick"] = function() end },
				{ ["title"] = string.format("Количество выписанных штрафных квитанций\t{00cc99}%s{ffffff} шт.", configuration["STATISTICS"]["police"]["tickets"]), ["onclick"] = function() end },
				{ ["title"] = string.format("Число объявлений в розыск\t{00cc99}%s{ffffff} раз(-а)", configuration["STATISTICS"]["police"]["suspects"]), ["onclick"] = function() end },
				{ ["title"] = string.format("Подозреваемые отслеживались\t{00cc99}%s{ffffff} раз(-а)", configuration["STATISTICS"]["police"]["setmark"]), ["onclick"] = function() end },
				{ ["title"] = string.format("Произведён обыск подозреваемых\t{00cc99}%s{ffffff} раз(-а)", configuration["STATISTICS"]["police"]["search"]), ["onclick"] = function() end },
				{ ["title"] = string.format("Количество изъятых наркотиков\t{00cc99}%s{ffffff} гр.", configuration["STATISTICS"]["police"]["drugs"]), ["onclick"] = function() end },
				{ ["title"] = string.format("Количество изъятых боеприпасов\t{00cc99}%s{ffffff} шт.", configuration["STATISTICS"]["police"]["bullets"]), ["onclick"] = function() end },
				{ ["title"] = string.format("Количество изъятых единиц оружия\t{00cc99}%s{ffffff} шт.", configuration["STATISTICS"]["police"]["weapons_number"]), ["onclick"] = function() end },
				{
					["title"] = "Подробная детализация об оружии\t{00cc99}Подробнее{ffffff}",
					["submenu"] = {
						["title"] = "Раздел детализации изъятого вооружения",
						{ ["title"] = "Параметр\tЗначение", ["onclick"] = function() end },
					}
				}
			}
		},
		{
			["title"] = "Пропагандисткая деятельность",
			["submenu"] = {
				["title"] = "Раздел пропагандисткой деятельности",
				{ ["title"] = "Параметр\tЗначение", ["onclick"] = function() end },
				{ ["title"] = string.format("Отредактировано объявлений\t{00cc99}%s{ffffff} шт.", configuration["STATISTICS"]["massmedia"]["ads"]), ["onclick"] = function() end }
			}
		},
		{
			["title"] = "Использование команд",
			["submenu"] = {
				["title"] = "Раздел использования команд",
				{ ["title"] = "Параметр\tЗначение", ["onclick"] = function() end },
			}
		}
	}

	local commands = {}
	for index, value in pairs(configuration["STATISTICS"]["commands"]) do
		table.insert(commands, { ["index"] = index, ["value"] = value })
	end
	table.sort(commands, function(a, b) return (a["value"] > b["value"]) end)

	local weapons = {}
	for index, value in pairs(configuration["STATISTICS"]["police"]["weapons"]) do
		table.insert(weapons, { ["index"] = string.gsub(index, "_", " "), ["value"] = value })
	end
	table.sort(weapons, function(a, b) return (a["value"] > b["value"]) end)

	for index, value in ipairs(commands) do
		if value["value"] > 1 then
			table.insert(dialog[5]["submenu"], {
				["title"] = string.format("/%s\t{00cc99}%s{ffffff} раз(-а)", value["index"], value["value"]),
				["onclick"] = function() end
			})
		end
	end

	for index, value in ipairs(weapons) do
		if value["value"] > 0 then
			table.insert(dialog[3]["submenu"][14]["submenu"], {
				["title"] = string.format("%s\t{00cc99}%s{ffffff} шт.", value["index"], value["value"]),
				["onclick"] = function() end
			})
		end
	end

	lua_thread.create(function() submenus_show(dialog, "Статистика пользователя", "Подробнее", "Закрыть", "Назад") end)
end

function command_helper_online()
	local players, result = {}, {
		{ ["title"] = "Организация\tОнлайн", ["onclick"] = function() end },
	}

	if player_status > 1 then
		table.insert(result, { 
			["title"] = "", 
			["submenu"] = {
				{ ["title"] = "Администрация",
					{ ["title"] = "nickname\tУровень\tТелефонный номер" }
				}
			}
		})
	end 

	for player_id = 0, 1000 do
		if isPlayerConnected(player_id) then
			local player_color = sampGetPlayerColor(player_id)
			local player_nickname = sampGetPlayerNickname(player_id)
			local player_score = sampGetPlayerScore(player_id)
			if not players[player_color] then players[player_color] = {} end

			table.insert(players[player_color], {
				nickname = player_nickname,
				score = player_score,
				player_id = player_id
			})

			if player_status > 1 then
				if configuration["DATABASE"]["player"][player_nickname] then
					if configuration["DATABASE"]["player"][player_nickname]["admin"] then
						local telephone = configuration["DATABASE"]["player"][player_nickname]["telephone"]
						table.insert(result[2]["submenu"], {
							title = string.format("%s (id %s) {%s}**\t%s\t%s", player_nickname, player_id, argb_to_hex(player_color), player_score, telephone and telephone or "Неизвестно")
						})
					end
				end
			end
		end
	end

	if player_status > 1 then
		-- online admins
		result[2]["title"] = string.format("Администрация\t%s", #result[2]["submenu"] - 1)
	end

	local space, players = players, {}
	for index, value in pairs(space) do
		table.insert(players, {
			color = argb_to_hex(index),
			fraction = fraction_color[index] and fraction_color[index][1] or "Прочее",
			players = value
		})
	end

	table.sort(players, function(a, b) return (#a["players"] > #b["players"]) end)

	for index, value in ipairs(players) do
		table.insert(result, {
			title = string.format("{%s}**{ffffff} %s\t%s", value["color"], value["fraction"], #value["players"]),
			submenu = {
				title = value["fraction"],
				{title = "#\tnickname\tУровень\tТелефонный номер"}
			}
		})

		for key, player in ipairs(value["players"]) do
			local telephone = configuration["DATABASE"]["player"][player["nickname"]] and configuration["DATABASE"]["player"][player["nickname"]]["telephone"]
			table.insert(result[#result]["submenu"], {
				title = string.format("%s\t%s (id %s) {%s}**\t%s\t%s", key, player["nickname"], player["player_id"], value["color"], player["score"], telephone and telephone or "Неизвестно")
			})
		end
	end

	lua_thread.create(function()
		submenus_show(result, "Онлайн на сервере", "Подробнее", "Закрыть", "Назад")
	end)
end

function command_helper_snake(size)
	if global_snake_game then
		global_snake_game = nil
	else
		if string.match(size, "(%d+)x(%d+)") then
			lua_thread.create(function()
				local size_w, size_h = string.match(size, "(%d+)x(%d+)")
				local size_w, size_h = tonumber(size_w), tonumber(size_h)

				global_snake_game = not global_snake_game
				local w, h = getScreenResolution()

				local game = {
					direction = 0,
					size_w = size_w,
					size_h = size_h,
					update_body_position = 0.2,
					last_update_body = os.clock(),
					food = {},
					body = {
						{
							x = math.ceil(w / 2 - size_w * 15 / 2),
							y = math.ceil(h / 2 - size_h * 15 / 2),
							color = 0xFF9FEAB6
						}
					},
					area = {
						size_w = size_w * 15,
						size_h = size_h * 15,
						top_left = {
							x = math.ceil(w / 2 - size_w * 15 / 2),
							y = math.ceil(h / 2 - size_h * 15 / 2)
						},
						down_right = {
							x = math.ceil(w / 2 + size_w * 15 / 2),
							y = math.ceil(h / 2 + size_h * 15 / 2)
						},
						blocks = {}
					}
				}

				for x = 0, game["size_w"] do -- заполняем поле цветными квадратиками
					local color = (math.fmod(x, 2) == 0) and 0xFF2A2A2A or 0xFF2C2C2C
					for y = 0, game["size_h"] do
						local color = math.fmod(y, 2) == 0 and (color == 0xFF2A2A2A and 0xFF2C2C2C or 0xFF2A2A2A) or color
						table.insert(game["area"]["blocks"], {
							x = game["area"]["top_left"]["x"] + x * 15,
							y = game["area"]["top_left"]["y"] + y * 15,
							color = color
						})
					end
				end

				lockPlayerControl(true) -- блокируем передвижения персонажа

				while global_snake_game do wait(0)
					if game["direction"] == 0 then -- делаем возможность начать играть
						printStringNow("PRESS ~g~W-A-S-D~w~ FOR START", 50)
						if wasKeyPressed(vkeys.VK_W) then game["direction"] = {x = 0, y = -15}
						elseif wasKeyPressed(vkeys.VK_S) then game["direction"] = {x = 0, y = 15}
						elseif wasKeyPressed(vkeys.VK_A) then game["direction"] = {x = -15, y = 0}
						elseif wasKeyPressed(vkeys.VK_D) then game["direction"] = {x = 15, y = 0}
						end
					else -- позволяем двигаться змею
						if wasKeyPressed(vkeys.VK_W) then game["direction"] = {x = 0, y = -15}
						elseif wasKeyPressed(vkeys.VK_S) then game["direction"] = {x = 0, y = 15}
						elseif wasKeyPressed(vkeys.VK_A) then game["direction"] = {x = -15, y = 0}
						elseif wasKeyPressed(vkeys.VK_D) then game["direction"] = {x = 15, y = 0}
						end

						if os.clock() - game["last_update_body"] > game["update_body_position"] then -- обновляем позицию змея
							if game["update_body"] then
								table.insert(game["body"], 1, {x = game["body"][1]["x"] + game["direction"]["x"], y = game["body"][1]["y"] + game["direction"]["y"], color = 0xFF90C887})
								game["update_body"] = false
							else
								table.insert(game["body"], 1, {x = game["body"][1]["x"] + game["direction"]["x"], y = game["body"][1]["y"] + game["direction"]["y"], color = 0xFF90C887})
								table.remove(game["body"], #game["body"])
							end

							if game["direction"] ~= 0 then -- проверяем находится ли змей в поле
								if game["body"][1]["x"] < game["area"]["top_left"]["x"] or game["body"][1]["x"] > game["area"]["down_right"]["x"] or game["body"][1]["y"] > game["area"]["down_right"]["y"] or game["body"][1]["y"] < game["area"]["top_left"]["y"] then
									chat(string.format("Нельзя биться головой о стены! Ваш счет в этой игре #{HEX}%s{}, игровое поле {HEX}%sx%s{}.", #game["body"] - 1, game["size_w"], game["size_h"]))
									lockPlayerControl(false)
									global_snake_game = nil
									return
								end
							end

							if game["body"][1]["x"] == game["food"]["x"] and game["body"][1]["y"] == game["food"]["y"] then -- проверяем сьел ли змей еду
								game["food"] = {}
								game["update_body"] = true
								game["update_body_position"] = game["update_body_position"] - 0.0025
							end

							if #game["body"] > 1 then -- проверяем не сьел ли змей сам себя
								for index = 2, #game["body"] do
									if game["body"][index]["color"] == 0xFF90C887 then game["body"][index]["color"] = 0xFF7BB671 end
									if game["body"][1]["x"] == game["body"][index]["x"] and game["body"][1]["y"] == game["body"][index]["y"] then
										chat(string.format("Змей не ест змея... Ваш счет в этой игре #{HEX}%s{}, игровое поле {HEX}%sx%s{}.", #game["body"] - 1, game["size_w"], game["size_h"]))
										lockPlayerControl(false)
										global_snake_game = nil
										return
									end
								end
							end

							game["last_update_body"] = os.clock()
						end
					end

					if not game["food"]["x"] then -- создаем еду, если ее кто-то сьел!
						local true_position = {}
						for x = game["area"]["top_left"]["x"], game["area"]["down_right"]["x"], 15 do
							for y = game["area"]["top_left"]["y"], game["area"]["down_right"]["y"], 15 do
								local is_found_snake_in_position = false
								for index, value in ipairs(game["body"]) do
									if value["x"] == x and value["y"] == y then is_found_snake_in_position = true end
								end
								if not is_found_snake_in_position then table.insert(true_position, {x = x, y = y}) end
							end
						end

						if #true_position == 0 then
							chat(string.format("Вы стали слишком упитанным, чтобы играть дальше! Ваш счет в этой игре #{HEX}%s{}, игровое поле {HEX}%sx%s{}.", #game["body"] - 1, game["size_w"], game["size_h"]))
							lockPlayerControl(false)
							global_snake_game = nil
							return
						else
							game["food"] = true_position[math.random(1, #true_position)]
						end
					end

					renderDrawBox(game["area"]["top_left"]["x"] - 2, game["area"]["top_left"]["y"] - 2, game["area"]["size_w"] + 19, game["area"]["size_h"] + 19, configuration["MAIN"]["settings"]["t_script_color"]) -- рисуем фон
					for index, value in ipairs(game["area"]["blocks"]) do -- рисуем поле
						renderDrawBox(value["x"], value["y"], 15, 15, value["color"])
					end

					if game["food"]["x"] then renderDrawBox(game["food"]["x"], game["food"]["y"], 15, 15, 0xFFDB4B5A) end -- рисуем еду

					for index, value in ipairs(game["body"]) do -- рисуем змея
						renderDrawBox(value["x"], value["y"], 15, 15, value["color"])
					end
				end

				lockPlayerControl(false) -- разблокируем передвижения персонажа
			end)
		else chat_error("Введите необходимые параметры для /helper_snake [размер поля в формате NxN].") end
	end
end

function command_helper_miner(size)
	if global_miner_game then
		global_miner_game = nil
	else
		if string.match(size, "(%d+)x(%d+) (%d+)") then
			lua_thread.create(function()
				local size_w, size_h, bombs = string.match(size, "(%d+)x(%d+) (%d+)")
				local size_w, size_h, bombs = tonumber(size_w), tonumber(size_h), tonumber(bombs)

				local w, h = getScreenResolution()
				global_miner_game = not global_miner_game

				local game = {
					status = 0,
					size_w = size_w,
					size_h = size_h,
					bombs = bombs,
					defused_bomb = 0,
					actually_defused_bomb = 0,
					time = {
						start = 0,
						stop = 0
					},
					area = {
						size_w = size_w * 30,
						size_h = size_h * 30,
						top_left = {
							x = math.ceil(w / 2 - (size_w + 1) * 30 / 2),
							y = math.ceil(h / 2 - (size_h + 1) * 30 / 2)
						},
						down_rigth = {
							x = math.ceil(w / 2 + (size_w + 1) * 30 / 2),
							y = math.ceil(h / 2 + (size_h + 1) * 30 / 2)
						},
						blocks = {}
					},
					positions = {}
				}

				local function open_miner_block(x, y, block) -- обрабатываем клеточки
					local total_defused_bombs = 0

					for expression_x = -1, 1 do -- открываем все нулевые клеточки вокруг указанной
						for expression_y = -1, 1 do
							local current_x, current_y = x + expression_x, y + expression_y
							if game["positions"][current_x] and game["positions"][current_x][current_y] then
								local t_index = game["positions"][current_x][current_y]
								if not game["area"]["blocks"][t_index]["is_open_block"] and game["area"]["blocks"][t_index]["bomb"] == 0 then
									game["area"]["blocks"][t_index]["is_open_block"] = 1
									open_miner_block(game["area"]["blocks"][t_index]["positions"]["x"], game["area"]["blocks"][t_index]["positions"]["y"], game["area"]["blocks"][t_index])
								else
									if game["area"]["blocks"][t_index]["is_open_block"] == 2 then total_defused_bombs = total_defused_bombs + 1 end
								end
							end
						end
					end

					if block["bomb"] <= total_defused_bombs then -- открываем все клеточки вокруг нашей клеточки, если бомбы уже закрыты
						for expression_x = -1, 1 do
							for expression_y = -1, 1 do
								local current_x, current_y = x + expression_x, y + expression_y
								if game["positions"][current_x] and game["positions"][current_x][current_y] then
									local t_index = game["positions"][current_x][current_y]
									if not game["area"]["blocks"][t_index]["is_open_block"] then
										if game["area"]["blocks"][t_index]["bomb"] == -1 then
											game["time"]["stop"] = os.clock()
											game["area"]["blocks"][t_index]["bomb"] = -2
											game["status"] = 1
											local time = game["time"]["stop"] - game["time"]["start"]
											chat(string.format("Осторожней с минами. Время #{HEX}%s{} ({HEX}%0.5f{} сек), игровое поле {HEX}%sx%s{} (%d бомб(-ы)).", os.date("%M:%S", time), time, game["size_w"], game["size_h"], game["bombs"]))
										else
											game["area"]["blocks"][t_index]["is_open_block"] = 1
										end
									end
								end
							end
						end
					end

					for index, value in ipairs(game["area"]["blocks"]) do -- открываем все клеточки вокруг пустых клеточек
						if value["bomb"] == 0 and value["is_open_block"] == 1 then
							local fx, fy = value["positions"]["x"], value["positions"]["y"]
							for expression_x = -1, 1 do
								for expression_y = -1, 1 do
									local current_x, current_y = fx + expression_x, fy + expression_y
									if game["positions"][current_x] and game["positions"][current_x][current_y] then
										local t_index = game["positions"][current_x][current_y]
										if not game["area"]["blocks"][t_index]["is_open_block"] then
											game["area"]["blocks"][t_index]["is_open_block"] = 1
										end
									end
								end
							end
						end
					end
				end

				local font = renderCreateFont("calibri", 12, font_flag.BOLD) -- добавляем шрифт

				for x = 0, game["size_w"] - 1 do -- размечаем поле на отдельные сектора
					local color = (math.fmod(x, 2) == 0) and 0xFF2A2A2A or 0xFF2D2D2D
					for y = 0, game["size_h"] - 1 do
						local color = math.fmod(y, 2) == 0 and (color == 0xFF2A2A2A and 0xFF2D2D2D or 0xFF2A2A2A) or color
						table.insert(game["area"]["blocks"], {
							x = game["area"]["top_left"]["x"] + x * 30,
							y = game["area"]["top_left"]["y"] + y * 30,
							positions = {x = x, y = y, tx = 0, ty = 0, mx = 0, my = 0},
							color = color,
							bomb = 0
						})
						if not game["positions"][x] then game["positions"][x] = {} end
						game["positions"][x][y] = #game["area"]["blocks"]
					end
				end

				while global_miner_game do wait(0)
					local mouse_x, mouse_y = getCursorPos()
					sampSetCursorMode(3)

					renderDrawBox(game["area"]["top_left"]["x"] - 2, game["area"]["top_left"]["y"] - 42, game["area"]["size_w"] + 4, 30, configuration["MAIN"]["settings"]["t_script_color"]) -- рисуем фон блока информации
					renderDrawBox(game["area"]["top_left"]["x"], game["area"]["top_left"]["y"] - 40, game["area"]["size_w"], 26, 0xFF2A2A2A) -- ещё один фон только черный

					renderDrawBox(game["area"]["top_left"]["x"] - 2, game["area"]["top_left"]["y"] - 2, game["area"]["size_w"] + 4, game["area"]["size_h"] + 4, configuration["MAIN"]["settings"]["t_script_color"]) -- рисуем фон

					if game["status"] == 0 then
						for t_index, value in ipairs(game["area"]["blocks"]) do
							if mouse_x > value["x"] and mouse_x < (value["x"] + 30) and mouse_y > value["y"] and mouse_y < (value["y"] + 30) then
								if wasKeyPressed(vkeys.VK_LBUTTON) then
									local function create_bomb_on_random_block()
										local index = math.random(1, #game["area"]["blocks"])
										if index ~= t_index and game["area"]["blocks"][index]["bomb"] ~= -1 then
											game["area"]["blocks"][index]["bomb"] = -1
										else
											create_bomb_on_random_block()
										end
									end

									for bombs = 1, game["bombs"] do -- минируем поле ***
										create_bomb_on_random_block()
									end

									for index, value in ipairs(game["area"]["blocks"]) do -- размечаем количество бомб около отдельного сектора
										if value["bomb"] == -1 then
											local current_x, current_y = value["positions"]["x"], value["positions"]["y"]
											for expression_x = -1, 1 do
												for expression_y = -1, 1 do
													local current_x, current_y = current_x + expression_x, current_y + expression_y
													if game["positions"][current_x] and game["positions"][current_x][current_y] then
														local t_index = game["positions"][current_x][current_y]
														if game["area"]["blocks"][t_index]["bomb"] ~= -1 then game["area"]["blocks"][t_index]["bomb"] = game["area"]["blocks"][t_index]["bomb"] + 1 end
													end
												end
											end
										end
									end

									for index, value in ipairs(game["area"]["blocks"]) do
										local fix_bomb = renderGetFontDrawTextLength(font, tostring(value["bomb"]))
										local fix_defused = renderGetFontDrawTextLength(font, "M")

										game["area"]["blocks"][index]["positions"]["tx"] = value["x"] + 15 - fix_bomb / 2
										game["area"]["blocks"][index]["positions"]["ty"] = value["y"] + 5

										game["area"]["blocks"][index]["positions"]["mx"] = value["x"] + 15 - fix_defused / 2
										game["area"]["blocks"][index]["positions"]["my"] = value["y"] + 5
									end

									game["area"]["blocks"][t_index]["is_open_block"] = 1
									open_miner_block(value["positions"]["x"], value["positions"]["y"], value)
									game["status"] = 2
									game["time"]["start"] = os.clock()
									break
								end
							end
						end
					elseif game["status"] == 1 then
						renderFontDrawText(font, os.date("%M:%S", game["time"]["stop"] - game["time"]["start"]), game["area"]["top_left"]["x"] + 4, game["area"]["top_left"]["y"] - 37, 0xbbFFFFFF)

						for index, value in ipairs(game["area"]["blocks"]) do
							if value["bomb"] == -1 then
								if value["is_open_block"] == 2 then
									renderDrawBox(value["x"], value["y"], 30, 30, 0xFF424949)
								end
								renderFontDrawText(font, "M", value["positions"]["mx"], value["positions"]["my"], 0xbbFFFFFF)
							else
								if value["bomb"] == -2 then
									renderDrawBox(value["x"], value["y"], 30, 30, 0xFF7B241C)
									renderFontDrawText(font, "M", value["positions"]["mx"], value["positions"]["my"], 0xbbFFFFFF)
								else
									renderDrawBox(value["x"], value["y"], 30, 30, value["color"])
									if value["bomb"] > 0 then
										renderFontDrawText(font, value["bomb"], value["positions"]["tx"], value["positions"]["ty"], 0xbbFFFFFF)
									end
								end
							end
						end
					elseif game["status"] == 2 then
						if game["actually_defused_bomb"] == game["bombs"] then
							if game["actually_defused_bomb"] == game["defused_bomb"] then
								game["status"] = 1
								game["time"]["stop"] = os.clock()
								local time = game["time"]["stop"] - game["time"]["start"]
								chat(string.format("Победа! Время #{HEX}%s{} ({HEX}%0.5f{} сек), игровое поле {HEX}%sx%s{} (%d бомб(-ы)).", os.date("%M:%S", time), time, game["size_w"], game["size_h"], game["bombs"]))

								-- save record
							end
						end

						renderFontDrawText(font, os.date("%M:%S", os.clock() - game["time"]["start"]), game["area"]["top_left"]["x"] + 4, game["area"]["top_left"]["y"] - 37, 0xbbFFFFFF)
						renderFontDrawText(font, string.format("Осталось бомб: %s", game["bombs"] - game["defused_bomb"]), game["area"]["top_left"]["x"] + 46, game["area"]["top_left"]["y"] - 37, 0xbbFFFFFF)

						for index, value in ipairs(game["area"]["blocks"]) do -- рисуем поле и обрабатываем поле!
							if value["is_open_block"] == 1 then
								renderDrawBox(value["x"], value["y"], 30, 30, value["color"])
								if value["bomb"] > 0 then
									renderFontDrawText(font, value["bomb"], value["positions"]["tx"], value["positions"]["ty"], 0xbbFFFFFF)
								end
							elseif value["is_open_block"] == 2 then
								renderDrawBox(value["x"], value["y"], 30, 30, 0xFF424949)
								renderFontDrawText(font, "M", value["positions"]["mx"], value["positions"]["my"], 0xbbFFFFFF)
							end

							if mouse_x > value["x"] and mouse_x < (value["x"] + 30) and mouse_y > value["y"] and mouse_y < (value["y"] + 30) then
								if wasKeyPressed(vkeys.VK_LBUTTON) then
									if value["bomb"] == -1 then
										game["area"]["blocks"][index]["bomb"] = -2
										game["status"] = 1
										game["time"]["stop"] = os.clock()
										local time = game["time"]["stop"] - game["time"]["start"]
										chat(string.format("Нельзя наступать на мины! Время #{HEX}%s{} ({HEX}%0.5f{} сек), игровое поле {HEX}%sx%s{} (%d бомб(-ы)).", os.date("%M:%S", time), time, game["size_w"], game["size_h"], game["bombs"]))
									else
										game["area"]["blocks"][index]["is_open_block"] = 1
										open_miner_block(value["positions"]["x"], value["positions"]["y"], value)
									end
								end

								if wasKeyPressed(vkeys.VK_RBUTTON) then
									if not value["is_open_block"] then
										if value["bomb"] == -1 then game["actually_defused_bomb"] = game["actually_defused_bomb"] + 1 end
										game["defused_bomb"] = game["defused_bomb"] + 1
										game["area"]["blocks"][index]["is_open_block"] = 2
									else
										if value["is_open_block"] == 2 then
											if value["bomb"] == -1 then game["actually_defused_bomb"] = game["actually_defused_bomb"] - 1 end
											game["defused_bomb"] = game["defused_bomb"] - 1
											game["area"]["blocks"][index]["is_open_block"] = 0
										end
									end
								end
							end
						end
					end
				end sampSetCursorMode(0)
			end)
		else chat_error("Введите необходимые параметры для /helper_miner [размер поля в формате NxN].") end
	end
end

function command_helper_ads(parametrs)
	mimgui_window("helper_ads")

	--[[if string.match(parametrs, "(%S+)") then
		local input_pattern = string.nlower(string.gsub(parametrs, "%p+", ""))
		local t_input_pattern = {}
		for word in string.gmatch(input_pattern, "[^%s]+") do table.insert(t_input_pattern, word) end

		local repeats = {}
		local result = {}

		local half_weights = {"прода", "купл", "цена", "бюдже", "свободн", "договор"}

		for index = table.maxn(configuration["ADS"]), 1, -1 do
			local received_ad = string.nlower(string.gsub(u8:decode(configuration["ADS"][index]["received_ad"]), "%p+", ""))
			local corrected_ad = string.nlower(string.gsub(u8:decode(configuration["ADS"][index]["corrected_ad"]), "(%p+)?(%s+)", ""))
			if not repeats[corrected_ad] then
				local t_received_ad = {}
				local matches = 0
				for word in string.gmatch(received_ad, "[^%s]+") do
					local is_word_have_half_weights = false
					for k1, v1 in ipairs(half_weights) do
						if string.match(word, v1) then is_word_have_half_weights = true end
					end
					table.insert(t_received_ad, { word, is_word_have_half_weights and 0.5 or 1 })
				end

				for k1, v1 in ipairs(t_input_pattern) do
					for k2, v2 in ipairs(t_received_ad) do
						if string.match(v2[1], v1) then
							if string.len(v1) > 2 and string.len(v2[1]) > 2 then matches = matches + v2[2] end
						end
					end
				end

				repeats[corrected_ad] = true

				if matches > 0 then table.insert(result, { index = index, matches = matches }) end
			end
		end

		table.sort(result, function(a, b) return a["matches"] > b["matches"] end)

		local dialog = { { title = "#\tЧасть объявления\tЧисло совпадений", onclick = function() end } }
		for index, value in ipairs(result) do
			table.insert(dialog, {
				title = string.format("%s\t%s\t%s", index, string.sub(u8:decode(configuration["ADS"][value["index"]["received_ad"]), 0, 50), value["matches"]),
				submenu = {
					title = string.format("Объявление #%s", value["index"]),
					{ title = "#\tЗначение", onclick = function() end },
					{ title = string.format("Отправлено\t%s", u8:decode(configuration["ADS"][value["index"]["received_ad"])), onclick = function() end },
					{ title = string.format("Отредактировано\t%s", u8:decode(configuration["ADS"][value["index"]["corrected_ad"])), onclick = function() end },
					{ title = string.format("Отправитель\t%s", configuration["ADS"][value["index"]["author"] and configuration["ADS"][value["index"]["author"] or "Неизвестно"), onclick = function() end },
					{ title = string.format("Дата\t%s", configuration["ADS"][value["index"]["finish_of_verification"] and os.date("%x, %X", configuration["ADS"][value["index"]["finish_of_verification"]) or "Неизвестно"), onclick = function() end },
				}
			})
		end

		lua_thread.create(function() submenus_show(dialog, "smart ad", "Подробнее", "Закрыть", "Назад") end)
	else
		chat_error("Введите необходимые параметры для /helper_ads [часть объявления].")
	end--]]
end

function command_lock(parametrs)
	if tonumber(parametrs) then
		last_used_vehicle_key["type"] = tonumber(parametrs)
		last_used_vehicle_key["time"] = os.time()
	else
		if configuration["MAIN"]["settings"]["quick_lock_doors"] then
			if last_used_vehicle_key["type"] then
				local probable_vehicles = {}
				for index, vehicle_handle in pairs(getAllVehicles()) do
					if doesVehicleExist(vehicle_handle) then
						local result, vehicle_id = sampGetVehicleIdByCarHandle(vehicle_handle)
						if result and t_smart_vehicle["vehicle"][vehicle_id] then
							local distance = getDistanceToVehicle(vehicle_handle)
							if distance < 50 then
								local vehicle_information = t_smart_vehicle["vehicle"][vehicle_id]
								if getCarModel(vehicle_handle) == vehicle_information["model"] then
									table.insert(probable_vehicles, {
										vehicle_handle = vehicle_handle,
										vehicle_id = vehicle_id,
										model = getCarModel(vehicle_handle),
										distance = distance,
										type = vehicle_information["type"]
									})
								end
							end
						end
					end
				end

				if table.maxn(probable_vehicles) > 0 then
					table.sort(probable_vehicles, function(a, b) return a["distance"] < b["distance"] end)
					local normal_vehicle_id = probable_vehicles[1]["model"] - 399
					local word = getCarDoorLockStatus(probable_vehicles[1]["vehicle_handle"]) == 0 and "закрыто" or "открыто"
					chat(string.format("Ваше транспортное средство (%s {HEX}%s{} #{HEX}%s{}) было %s умным ключом.", tf_vehicle_type_name[3][t_vehicle_type[normal_vehicle_id]], t_vehicle_name[normal_vehicle_id], probable_vehicles[1]["vehicle_id"], word))
					sampSendChat(string.format("/lock %s", probable_vehicles[1]["type"]))
					return
				end
			end
		end
	end

	sampSendChat(string.format("/lock %s", parametrs))
end

function command_medhelp(parametrs)
	if string.match(parametrs, "(%d+)") then
		local id, price = string.match(parametrs, "(%d+) (%d+)") and string.match(parametrs, "(%d+) (%d+)") or parametrs, " "
		if isPlayerConnected(id) then
			if sampGetDistanceToPlayer(id) < 3 then
				lua_thread.create(function()
					local male = configuration["MAIN"]["information"]["sex"] and "female" or "male"
					local acting = configuration["CUSTOM"]["SYSTEM"][male]["medhelp"]["variations"]
					local acting = acting[math.random(1, #acting)]
					final_command_handler(acting, {id, price})
				end)
			else chat("Данный игрок находится слишком далеко от Вас.") end
		else chat("Данный игрок не подключён к серверу, проверьте правильность введёного ID.") end
	else chat_error("Введите необходимые параметры для /medhelp [id игрока] [стоимость лечения].") end
end

function command_tracker(parametrs)
	if string.match(parametrs, "^(%d+) (%d)$") then
		local id, stars = string.match(parametrs, "^(%d+) (%d)$")
		if isPlayerConnected(id) then
			if sampGetDistanceToPlayer(id) < 50 then
				lua_thread.create(function()
					local male = configuration["MAIN"]["information"]["sex"] and "female" or "male"
					local acting = configuration["CUSTOM"]["SYSTEM"][male]["tracker"]["variations"]
					local acting = acting[math.random(1, #acting)]
					final_command_handler(acting, {id, stars})
				end)
			else chat("Данный игрок находится слишком далеко от Вас.") end
		else chat("Данный игрок не подключён к серверу, проверьте правильность введёного ID.") end
	else chat_error("Введите необходимые параметры для /tracker [id игрока] [уровень розыска].") end
end

function command_animations()
	mimgui_window("animations")
end

function command_sad(parametrs)
	if time_take_ads then
		time_take_ads = false 
		for index, value in ipairs(t_player_text) do
			if value["type"] == 4 then 
				destroy_player_text(index)
			end
		end
		destroy_assistant_thread("time_take_ads")
	else 
		if not tonumber(parametrs) then 
			chat_error("Введите необходимые параметры для /sad [время в секундах].")
			return false
		end

		delay_take_ads = tonumber(parametrs)
		time_take_ads = os.clock()
		create_player_text(4)
		create_assistant_thread("time_take_ads")
	end
end

function command_helper_admins(parametrs)
	if player_status < 1 then return false end
	if tonumber(parametrs) then
		if isPlayerConnected(parametrs) then
			local admin_nickname = sampGetPlayerName(parametrs)
			local admin_color = sampGetPlayerColor(parametrs)

			if not configuration["DATABASE"]["player"][admin_nickname] then 
				configuration["DATABASE"]["player"][admin_nickname] = {} 
			end

			configuration["DATABASE"]["player"][admin_nickname]["admin"] = not configuration["DATABASE"]["player"][admin_nickname]["admin"]
			local admin_status = configuration["DATABASE"]["player"][admin_nickname]["admin"]

			chat(string.format("Администратор {%s}%s{} (id %s) был %s.", argb_to_hex(admin_color), admin_nickname, parametrs, (admin_status and "внесён в список" or "вынесен из списка")))
		else chat("Данный игрок не подключён к серверу, проверьте правильность введёного ID.") end
	elseif string.match(parametrs, "(%S+)") and not string.match(parametrs, "(%s+)") then
		local admin_nickname = parametrs
		if not configuration["DATABASE"]["player"][admin_nickname] then 
			configuration["DATABASE"]["player"][admin_nickname] = {} 
		end

		configuration["DATABASE"]["player"][admin_nickname]["admin"] = not configuration["DATABASE"]["player"][admin_nickname]["admin"]
		local admin_status = configuration["DATABASE"]["player"][admin_nickname]["admin"]

		chat(string.format("Администратор %s%s{} был %s.", configuration["MAIN"]["settings"]["script_color"], admin_nickname, (admin_status and "внесён в список" or "вынесен из списка")))
	else chat_error("Введите необходимые параметры для /helper_admins [id или nickname администратора].") end
end

function command_unmask(parametrs)
	if string.match(parametrs, "^(%d+)$") then
		local player_id = string.match(parametrs, "^(%d+)$")
		if isPlayerConnected(player_id) then
			if sampGetDistanceToPlayer(player_id) < 3 then
				lua_thread.create(function()
					local male = configuration["MAIN"]["information"]["sex"] and "female" or "male"
					local acting = configuration["CUSTOM"]["SYSTEM"][male]["unmask"]["variations"]
					local acting = acting[math.random(1, #acting)]
					final_command_handler(acting, { player_id })
				end)
			else chat("Данный игрок находится слишком далеко от Вас.") end
		else chat("Данный игрок не подключён к серверу, проверьте правильность введёного ID.") end
	else chat_error("Введите необходимые параметры для /unmask [id игрока].") end
end
-- !callback

-- function
function explode_argb(argb)
  local a = bit.band(bit.rshift(argb, 24), 0xFF)
  local r = bit.band(bit.rshift(argb, 16), 0xFF)
  local g = bit.band(bit.rshift(argb, 8), 0xFF)
  local b = bit.band(argb, 0xFF)
  return a, r, g, b
end

function join_argb(a, r, g, b)
  local argb = b  -- b
  argb = bit.bor(argb, bit.lshift(g, 8))  -- g
  argb = bit.bor(argb, bit.lshift(r, 16)) -- r
  argb = bit.bor(argb, bit.lshift(a, 24)) -- a
  return argb
end

function chat(...)
	local output = string.format("%s|{CECECE}", configuration["MAIN"]["settings"]["script_color"])
	for index, value in pairs({...}) do output = string.format("%s %s", output, value) end
	if string.match(output, "{HEX}") then output = string.gsub(output, "{HEX}", configuration["MAIN"]["settings"]["script_color"]) end
	if string.match(output, "{}") then output = string.gsub(output, "{}", "{CECECE}") end
	sampAddChatMessage(output, configuration["MAIN"]["settings"]["timestamp_color"])
end

function chat_error(text)
	if string.match(text, "{}") then text = string.gsub(text, "{}", "{CECECE}") end
	local text = string.gsub(text, "%[", string.format("[%s", configuration["MAIN"]["settings"]["script_color"]))
	local text = string.gsub(text, "%]", "{CECECE}%]")
	sampAddChatMessage(("%s| {CECECE}%s"):format(configuration["MAIN"]["settings"]["script_color"], string.gsub(tostring(text), "{HEX}", configuration["MAIN"]["settings"]["script_color"])), configuration["MAIN"]["settings"]["timestamp_color"])
end

function isPlayerConnected(id)
	local result, player_id = sampGetPlayerIdByCharHandle(playerPed)
	return result and (sampIsPlayerConnected(id) or tonumber(id) == tonumber(player_id))
end

function sampGetDistanceToPlayer(id)
	local result, player_id = sampGetPlayerIdByCharHandle(playerPed)
	if result and player_id == tonumber(id) then return 1 end
	if isPlayerConnected(id) then
		local getted, ped = sampGetCharHandleBySampPlayerId(id)
		if getted then
			local x1, y1, z1 = getCharCoordinates(playerPed)
			local x2, y2, z2 = getCharCoordinates(ped)
			return getDistanceBetweenCoords3d(x1, y1, z1, x2, y2, z2)
		end
	end return 9999
end

function getDistanceToPlayer(player_handle)
	if doesCharExist(player_handle) then
		local x1, y1, z1 = getCharCoordinates(playerPed)
		local x2, y2, z2 = getCharCoordinates(player_handle)
		return getDistanceBetweenCoords3d(x1, y1, z1, x2, y2, z2)
	end return 9999
end

function sampGetDistanceToVehicle(vehicle_id)
	local result, vehicle_handle = sampGetVehicleIdByCarHandle(vehicle_id)
	if result and doesVehicleExist(vehicle_handle) then
		local vehicle_x, vehicle_y, vehicle_z = getCarCoordinates(vehicle_handle)
		local player_x, player_y, player_z = getCharCoordinates(playerPed)
		return getDistanceBetweenCoords3d(vehicle_x, vehicle_y, vehicle_z, player_x, player_y, player_z)
	else return 9999 end
end

function getDistanceToVehicle(vehicle_handle)
	if doesVehicleExist(vehicle_handle) then
		local vehicle_x, vehicle_y, vehicle_z = getCarCoordinates(vehicle_handle)
		local player_x, player_y, player_z = getCharCoordinates(playerPed)
		return getDistanceBetweenCoords3d(vehicle_x, vehicle_y, vehicle_z, player_x, player_y, player_z)
	else return 9999 end
end

function sampGetPlayerName(id)
	return isPlayerConnected(id) and sampGetPlayerNickname(id)
end

function parameter_handler(input)
	local parametrs = {}
	for value in string.gmatch(input, "[^%s]+") do
		if string.match(value, "(%d+)") and string.match(value, "(%D+)") then
			if #parametrs > 0 then
				if string.match(parametrs[#parametrs], "(%d+)") and not string.match(parametrs[#parametrs], "(%D+)") then
					parametrs[#parametrs + 1] = value
				else
					parametrs[#parametrs] = string.format("%s %s", parametrs[#parametrs], value)
				end
			else
				parametrs[1] = value
			end
		elseif string.match(value, "(%d+)") then
			parametrs[#parametrs + 1] = value
		elseif string.match(value, "(%S+)") then
			if #parametrs > 0 then
				if string.match(parametrs[#parametrs], "(%d+)") and not string.match(parametrs[#parametrs], "(%D+)") then
					parametrs[#parametrs + 1] = value
				else
					parametrs[#parametrs] = string.format("%s %s", parametrs[#parametrs], value)
				end
			else
				parametrs[1] = value
			end
		end
	end return parametrs
end

function command_handler(profile, command, parametrs)
	if configuration["CUSTOM"]["USERS"][profile] then
		if configuration["CUSTOM"]["USERS"][profile][command] then
			local cloud = configuration["CUSTOM"]["USERS"][profile][command]
			local parametr_block = {}

			if cloud["parametrs_amount"] > 0 then
				parametr_block = parameter_handler(parametrs)
				if not (parametr_block and #parametr_block == cloud["parametrs_amount"]) then
					if cloud["parametrs_amount"] > 0 then
						for index = 1, cloud["parametrs_amount"] do
							if error_message then
								error_message = ("%s [параметр %s]"):format(error_message, index)
							else
								error_message = string.format("[параметр %s]", index)
							end
						end
					end
					chat_error(("Введите необходимые параметры для /%s %s."):format(cloud["command"], error_message))
					return
				end
			end

			local content = cloud["variations"][math.random(1, #cloud["variations"])]
			final_command_handler(content, parametr_block, profile, command)

		else chat_error(("Произошла ошибка [#2] при попытке выполнить команду [%s]."):format(command)) end
	else chat_error(("Произошла ошибка [#1] при попытке выполнить команду [%s]."):format(command)) end
end

function final_command_handler(array, parametrs_block, profile, command)
	if table.maxn(array) > 5 then chat("Чтобы прервать выполнение отыгровки нажмите клавишу {HEX}X{}.") end

	global_command_handler = true
	for index, value in ipairs(array) do
		local code = u8:decode(value)
		if string.match(code, "%$wait (%d+)") then
			local delay = tonumber(string.match(code, "%$wait (%d+)")) / 1000
			local start_time = os.clock()
			while os.clock() - start_time < delay do wait(0)
				if global_break_command then break end
			end
		elseif string.match(code, "%$chat (%S+)") then chat(string.match(code, "%$chat (%S+)"))
		elseif string.match(code, "%$script (%S+), (%S+), (%S+)") then
			local profile1, command1, parametrs1 = string.match(code, "%$script (.+), (.+), (.+)")
			if command1 == command then return end
			lua_thread.create(function() command_handler(profile1, command1, line_handler(parametrs1, parametr_block)) end)
		elseif string.match(code, "%$global (%S+), (%S+)") then
			local function1, parametrs1 = string.match(code, "%$global (%S+), (.+)")
			if not _G[function1] then return end
			_G[function1](parametrs1)
		else sampSendChat(line_handler(code, parametrs_block)) end

		if global_break_command then
			chat(string.format("Выполнение команды ({HEX}%s{}) было приостановлено.", command or "системная команда"))
			global_break_command = nil
			break
		end
	end
	global_command_handler = nil
end

function line_handler(input, parametrs_block)
	for index, value in ipairs(handler_tags) do
		if string.match(input, value[1]) then input = string.gsub(input, value[1], value[2]) end
	end

	for value in string.gmatch(input, "{(%d)}") do
		local index = tonumber(value)
		if index and parametrs_block[index] then input = string.gsub(input, ("{%d}"):format(index), parametrs_block[index]) end
	end

	if string.match(input, "%$rpname%.(%d+)") then
		for value in string.gmatch(input, "%$rpname%.(%d+)") do
			local result = sampGetPlayerName(value)
			local player_name = result and string.gsub(result, "_", " ")
			input = string.gsub(input, string.format("$rpname.%d", value), tostring(player_name))
		end
	end

	if string.match(input, "%$name%.(%d+)") then
		for value in string.gmatch(input, "%$name%.(%d+)") do
			local result = sampGetPlayerName(value)
			local player_name = result and result or ""
			input = string.gsub(input, string.format("$name.%d", value), tostring(player_name))
		end
	end return input
end

function greeting_depending_on_the_time()
	local hour = tonumber(os.date("%H"))
	if hour > 3 and hour <= 12 then       return "Доброе утро"
	elseif hour > 12 and hour <= 18 then  return "Добрый день"
	elseif hour > 18 and hour <= 22 then  return "Добрый вечер"
	elseif hour > 22 and hour <= 3 then   return "Доброй ночи"
	else return "Здравствуйте" end
end

function sampGetMarkCharByVehicle(ped) -- "L (Lincoln)", "A (Adam)", "M (Mary)", "C (Charley)", "D (David)", "H (Henry)"
	if isCharSittingInAnyCar(ped) then
		local vehicle = storeCarCharIsInNoSave(ped)

		if doesVehicleExist(vehicle) then
			local model = getCarModel(vehicle)

			if model >= 596 and model <= 599 then
				local result, int = getNumberOfPassengers(vehicle)
				if result and int > 0 then
					for i = 0, getMaximumNumberOfPassengers(vehicle) do
						if i == 3 then
							passenger = getDriverOfCar(vehicle)
						else
							if not isCarPassengerSeatFree(vehicle, i) then
								passenger = getCharInCarPassengerSeat(vehicle, i)
							end
						end

						if passenger ~= ped and sampIsPoliceOfficer(passenger) then
							return "A", 1
						end
					end
				end return "L", 0
			elseif model == 601 or model == 427 or model == 528 then
				return "C", 3
			elseif model == 415 then
				return "H", 5
			elseif model == 523 then
				return "M", 2
			end
		end
	end return "Unit", 0
end

function sampIsPoliceOfficer(player_handle)
	local result, player_id = sampGetPlayerIdByCharHandle(player_handle)
	if result then
		local player_color = sampGetPlayerColor(player_id)
		if player_color == 4278190335 then
			return true
		elseif player_color == 2236962 then
			local skin = "-265-266-267-280-281-282-283-284-285-286-288-300-301-302-303-304-305-306-307-310-311-"
			return string.find(skin, "%-" .. getCharModel(player_handle) .. "%-")
		else
			if sampGetPlayerArmor(player_id) > 0 then
				local is = { [4278220149] = true, [4288230246] = true, [4290445312] = true, [4291624704] = true, [4288243251] = true }
				if not is[player_color] then
					return true
				end
			end
		end
	end
end

function sampIsPoliceOfficerById(player_id)
	local result, player_handle = sampGetCharHandleBySampPlayerId(player_id)
	local result, player_id = sampGetPlayerIdByCharHandle(player_handle)
	if result then
		local player_color = sampGetPlayerColor(player_id)
		if player_color == 4278190335 then
			return true
		elseif player_color == 2236962 then
			local skin = "-265-266-267-280-281-282-283-284-285-286-288-300-301-302-303-304-305-306-307-310-311-"
			return string.find(skin, "%-" .. getCharModel(player_handle) .. "%-")
		else
			if sampGetPlayerArmor(player_id) > 0 then
				local is = { [4278220149] = true, [4288230246] = true, [4290445312] = true, [4291624704] = true, [4288243251] = true }
				if not is[player_color] then
					return true
				end
			end
		end
	end
end

function calculateZone(x, y, z)
	if not x then x, y, z = getCharCoordinates(playerPed) end

    local streets = {{"Avispa Country Club", -2667.810, -302.135, -28.831, -2646.400, -262.320, 71.169},
    {"Easter Bay Airport", -1315.420, -405.388, 15.406, -1264.400, -209.543, 25.406},
    {"Avispa Country Club", -2550.040, -355.493, 0.000, -2470.040, -318.493, 39.700},
    {"Easter Bay Airport", -1490.330, -209.543, 15.406, -1264.400, -148.388, 25.406},
    {"Garcia", -2395.140, -222.589, -5.3, -2354.090, -204.792, 200.000},
    {"Shady Cabin", -1632.830, -2263.440, -3.0, -1601.330, -2231.790, 200.000},
    {"East Los Santos", 2381.680, -1494.030, -89.084, 2421.030, -1454.350, 110.916},
    {"LVA Freight Depot", 1236.630, 1163.410, -89.084, 1277.050, 1203.280, 110.916},
    {"Blackfield Intersection", 1277.050, 1044.690, -89.084, 1315.350, 1087.630, 110.916},
    {"Avispa Country Club", -2470.040, -355.493, 0.000, -2270.040, -318.493, 46.100},
    {"Temple", 1252.330, -926.999, -89.084, 1357.000, -910.170, 110.916},
    {"Unity Station", 1692.620, -1971.800, -20.492, 1812.620, -1932.800, 79.508},
    {"LVA Freight Depot", 1315.350, 1044.690, -89.084, 1375.600, 1087.630, 110.916},
    {"Los Flores", 2581.730, -1454.350, -89.084, 2632.830, -1393.420, 110.916},
    {"Starfish Casino", 2437.390, 1858.100, -39.084, 2495.090, 1970.850, 60.916},
    {"Easter Bay Chemicals", -1132.820, -787.391, 0.000, -956.476, -768.027, 200.000},
    {"Downtown Los Santos", 1370.850, -1170.870, -89.084, 1463.900, -1130.850, 110.916},
    {"Esplanade East", -1620.300, 1176.520, -4.5, -1580.010, 1274.260, 200.000},
    {"Market Station", 787.461, -1410.930, -34.126, 866.009, -1310.210, 65.874},
    {"Linden Station", 2811.250, 1229.590, -39.594, 2861.250, 1407.590, 60.406},
    {"Montgomery Intersection", 1582.440, 347.457, 0.000, 1664.620, 401.750, 200.000},
    {"Frederick Bridge", 2759.250, 296.501, 0.000, 2774.250, 594.757, 200.000},
    {"Yellow Bell Station", 1377.480, 2600.430, -21.926, 1492.450, 2687.360, 78.074},
    {"Downtown Los Santos", 1507.510, -1385.210, 110.916, 1582.550, -1325.310, 335.916},
    {"Jefferson", 2185.330, -1210.740, -89.084, 2281.450, -1154.590, 110.916},
    {"Mulholland", 1318.130, -910.170, -89.084, 1357.000, -768.027, 110.916},
    {"Avispa Country Club", -2361.510, -417.199, 0.000, -2270.040, -355.493, 200.000},
    {"Jefferson", 1996.910, -1449.670, -89.084, 2056.860, -1350.720, 110.916},
    {"Julius Thruway West", 1236.630, 2142.860, -89.084, 1297.470, 2243.230, 110.916},
    {"Jefferson", 2124.660, -1494.030, -89.084, 2266.210, -1449.670, 110.916},
    {"Julius Thruway North", 1848.400, 2478.490, -89.084, 1938.800, 2553.490, 110.916},
    {"Rodeo", 422.680, -1570.200, -89.084, 466.223, -1406.050, 110.916},
    {"Cranberry Station", -2007.830, 56.306, 0.000, -1922.000, 224.782, 100.000},
    {"Downtown Los Santos", 1391.050, -1026.330, -89.084, 1463.900, -926.999, 110.916},
    {"Redsands West", 1704.590, 2243.230, -89.084, 1777.390, 2342.830, 110.916},
    {"Little Mexico", 1758.900, -1722.260, -89.084, 1812.620, -1577.590, 110.916},
    {"Blackfield Intersection", 1375.600, 823.228, -89.084, 1457.390, 919.447, 110.916},
    {"Los Santos International", 1974.630, -2394.330, -39.084, 2089.000, -2256.590, 60.916},
    {"Beacon Hill", -399.633, -1075.520, -1.489, -319.033, -977.516, 198.511},
    {"Rodeo", 334.503, -1501.950, -89.084, 422.680, -1406.050, 110.916},
    {"Richman", 225.165, -1369.620, -89.084, 334.503, -1292.070, 110.916},
    {"Downtown Los Santos", 1724.760, -1250.900, -89.084, 1812.620, -1150.870, 110.916},
    {"The Strip", 2027.400, 1703.230, -89.084, 2137.400, 1783.230, 110.916},
    {"Downtown Los Santos", 1378.330, -1130.850, -89.084, 1463.900, -1026.330, 110.916},
    {"Blackfield Intersection", 1197.390, 1044.690, -89.084, 1277.050, 1163.390, 110.916},
    {"Conference Center", 1073.220, -1842.270, -89.084, 1323.900, -1804.210, 110.916},
    {"Montgomery", 1451.400, 347.457, -6.1, 1582.440, 420.802, 200.000},
    {"Foster Valley", -2270.040, -430.276, -1.2, -2178.690, -324.114, 200.000},
    {"Blackfield Chapel", 1325.600, 596.349, -89.084, 1375.600, 795.010, 110.916},
    {"Los Santos International", 2051.630, -2597.260, -39.084, 2152.450, -2394.330, 60.916},
    {"Mulholland", 1096.470, -910.170, -89.084, 1169.130, -768.027, 110.916},
    {"Yellow Bell Gol Course", 1457.460, 2723.230, -89.084, 1534.560, 2863.230, 110.916},
    {"The Strip", 2027.400, 1783.230, -89.084, 2162.390, 1863.230, 110.916},
    {"Jefferson", 2056.860, -1210.740, -89.084, 2185.330, -1126.320, 110.916},
    {"Mulholland", 952.604, -937.184, -89.084, 1096.470, -860.619, 110.916},
    {"Aldea Malvada", -1372.140, 2498.520, 0.000, -1277.590, 2615.350, 200.000},
    {"Las Colinas", 2126.860, -1126.320, -89.084, 2185.330, -934.489, 110.916},
    {"Las Colinas", 1994.330, -1100.820, -89.084, 2056.860, -920.815, 110.916},
    {"Richman", 647.557, -954.662, -89.084, 768.694, -860.619, 110.916},
    {"LVA Freight Depot", 1277.050, 1087.630, -89.084, 1375.600, 1203.280, 110.916},
    {"Julius Thruway North", 1377.390, 2433.230, -89.084, 1534.560, 2507.230, 110.916},
    {"Willowfield", 2201.820, -2095.000, -89.084, 2324.000, -1989.900, 110.916},
    {"Julius Thruway North", 1704.590, 2342.830, -89.084, 1848.400, 2433.230, 110.916},
    {"Temple", 1252.330, -1130.850, -89.084, 1378.330, -1026.330, 110.916},
    {"Little Mexico", 1701.900, -1842.270, -89.084, 1812.620, -1722.260, 110.916},
    {"Queens", -2411.220, 373.539, 0.000, -2253.540, 458.411, 200.000},
    {"Las Venturas Airport", 1515.810, 1586.400, -12.500, 1729.950, 1714.560, 87.500},
    {"Richman", 225.165, -1292.070, -89.084, 466.223, -1235.070, 110.916},
    {"Temple", 1252.330, -1026.330, -89.084, 1391.050, -926.999, 110.916},
    {"East Los Santos", 2266.260, -1494.030, -89.084, 2381.680, -1372.040, 110.916},
    {"Julius Thruway East", 2623.180, 943.235, -89.084, 2749.900, 1055.960, 110.916},
    {"Willowfield", 2541.700, -1941.400, -89.084, 2703.580, -1852.870, 110.916},
    {"Las Colinas", 2056.860, -1126.320, -89.084, 2126.860, -920.815, 110.916},
    {"Julius Thruway East", 2625.160, 2202.760, -89.084, 2685.160, 2442.550, 110.916},
    {"Rodeo", 225.165, -1501.950, -89.084, 334.503, -1369.620, 110.916},
    {"Las Brujas", -365.167, 2123.010, -3.0, -208.570, 2217.680, 200.000},
    {"Julius Thruway East", 2536.430, 2442.550, -89.084, 2685.160, 2542.550, 110.916},
    {"Rodeo", 334.503, -1406.050, -89.084, 466.223, -1292.070, 110.916},
    {"Vinewood", 647.557, -1227.280, -89.084, 787.461, -1118.280, 110.916},
    {"Rodeo", 422.680, -1684.650, -89.084, 558.099, -1570.200, 110.916},
    {"Julius Thruway North", 2498.210, 2542.550, -89.084, 2685.160, 2626.550, 110.916},
    {"Downtown Los Santos", 1724.760, -1430.870, -89.084, 1812.620, -1250.900, 110.916},
    {"Rodeo", 225.165, -1684.650, -89.084, 312.803, -1501.950, 110.916},
    {"Jefferson", 2056.860, -1449.670, -89.084, 2266.210, -1372.040, 110.916},
    {"Hampton Barns", 603.035, 264.312, 0.000, 761.994, 366.572, 200.000},
    {"Temple", 1096.470, -1130.840, -89.084, 1252.330, -1026.330, 110.916},
    {"Kincaid Bridge", -1087.930, 855.370, -89.084, -961.950, 986.281, 110.916},
    {"Verona Beach", 1046.150, -1722.260, -89.084, 1161.520, -1577.590, 110.916},
    {"Commerce", 1323.900, -1722.260, -89.084, 1440.900, -1577.590, 110.916},
    {"Mulholland", 1357.000, -926.999, -89.084, 1463.900, -768.027, 110.916},
    {"Rodeo", 466.223, -1570.200, -89.084, 558.099, -1385.070, 110.916},
    {"Mulholland", 911.802, -860.619, -89.084, 1096.470, -768.027, 110.916},
    {"Mulholland", 768.694, -954.662, -89.084, 952.604, -860.619, 110.916},
    {"Julius Thruway South", 2377.390, 788.894, -89.084, 2537.390, 897.901, 110.916},
    {"Idlewood", 1812.620, -1852.870, -89.084, 1971.660, -1742.310, 110.916},
    {"Ocean Docks", 2089.000, -2394.330, -89.084, 2201.820, -2235.840, 110.916},
    {"Commerce", 1370.850, -1577.590, -89.084, 1463.900, -1384.950, 110.916},
    {"Julius Thruway North", 2121.400, 2508.230, -89.084, 2237.400, 2663.170, 110.916},
    {"Temple", 1096.470, -1026.330, -89.084, 1252.330, -910.170, 110.916},
    {"Glen Park", 1812.620, -1449.670, -89.084, 1996.910, -1350.720, 110.916},
    {"Easter Bay Airport", -1242.980, -50.096, 0.000, -1213.910, 578.396, 200.000},
    {"Martin Bridge", -222.179, 293.324, 0.000, -122.126, 476.465, 200.000},
    {"The Strip", 2106.700, 1863.230, -89.084, 2162.390, 2202.760, 110.916},
    {"Willowfield", 2541.700, -2059.230, -89.084, 2703.580, -1941.400, 110.916},
    {"Marina", 807.922, -1577.590, -89.084, 926.922, -1416.250, 110.916},
    {"Las Venturas Airport", 1457.370, 1143.210, -89.084, 1777.400, 1203.280, 110.916},
    {"Idlewood", 1812.620, -1742.310, -89.084, 1951.660, -1602.310, 110.916},
    {"Esplanade East", -1580.010, 1025.980, -6.1, -1499.890, 1274.260, 200.000},
    {"Downtown Los Santos", 1370.850, -1384.950, -89.084, 1463.900, -1170.870, 110.916},
    {"The Mako Span", 1664.620, 401.750, 0.000, 1785.140, 567.203, 200.000},
    {"Rodeo", 312.803, -1684.650, -89.084, 422.680, -1501.950, 110.916},
    {"Pershing Square", 1440.900, -1722.260, -89.084, 1583.500, -1577.590, 110.916},
    {"Mulholland", 687.802, -860.619, -89.084, 911.802, -768.027, 110.916},
    {"Gant Bridge", -2741.070, 1490.470, -6.1, -2616.400, 1659.680, 200.000},
    {"Las Colinas", 2185.330, -1154.590, -89.084, 2281.450, -934.489, 110.916},
    {"Mulholland", 1169.130, -910.170, -89.084, 1318.130, -768.027, 110.916},
    {"Julius Thruway North", 1938.800, 2508.230, -89.084, 2121.400, 2624.230, 110.916},
    {"Commerce", 1667.960, -1577.590, -89.084, 1812.620, -1430.870, 110.916},
    {"Rodeo", 72.648, -1544.170, -89.084, 225.165, -1404.970, 110.916},
    {"Roca Escalante", 2536.430, 2202.760, -89.084, 2625.160, 2442.550, 110.916},
    {"Rodeo", 72.648, -1684.650, -89.084, 225.165, -1544.170, 110.916},
    {"Market", 952.663, -1310.210, -89.084, 1072.660, -1130.850, 110.916},
    {"Las Colinas", 2632.740, -1135.040, -89.084, 2747.740, -945.035, 110.916},
    {"Mulholland", 861.085, -674.885, -89.084, 1156.550, -600.896, 110.916},
    {"King`s", -2253.540, 373.539, -9.1, -1993.280, 458.411, 200.000},
    {"Redsands East", 1848.400, 2342.830, -89.084, 2011.940, 2478.490, 110.916},
    {"Downtown", -1580.010, 744.267, -6.1, -1499.890, 1025.980, 200.000},
    {"Conference Center", 1046.150, -1804.210, -89.084, 1323.900, -1722.260, 110.916},
    {"Richman", 647.557, -1118.280, -89.084, 787.461, -954.662, 110.916},
    {"Ocean Flats", -2994.490, 277.411, -9.1, -2867.850, 458.411, 200.000},
    {"Greenglass College", 964.391, 930.890, -89.084, 1166.530, 1044.690, 110.916},
    {"Glen Park", 1812.620, -1100.820, -89.084, 1994.330, -973.380, 110.916},
    {"LVA Freight Depot", 1375.600, 919.447, -89.084, 1457.370, 1203.280, 110.916},
    {"Regular Tom", -405.770, 1712.860, -3.0, -276.719, 1892.750, 200.000},
    {"Verona Beach", 1161.520, -1722.260, -89.084, 1323.900, -1577.590, 110.916},
    {"East Los Santos", 2281.450, -1372.040, -89.084, 2381.680, -1135.040, 110.916},
    {"Caligula`s Palace", 2137.400, 1703.230, -89.084, 2437.390, 1783.230, 110.916},
    {"Idlewood", 1951.660, -1742.310, -89.084, 2124.660, -1602.310, 110.916},
    {"Pilgrim", 2624.400, 1383.230, -89.084, 2685.160, 1783.230, 110.916},
    {"Idlewood", 2124.660, -1742.310, -89.084, 2222.560, -1494.030, 110.916},
    {"Queens", -2533.040, 458.411, 0.000, -2329.310, 578.396, 200.000},
    {"Downtown", -1871.720, 1176.420, -4.5, -1620.300, 1274.260, 200.000},
    {"Commerce", 1583.500, -1722.260, -89.084, 1758.900, -1577.590, 110.916},
    {"East Los Santos", 2381.680, -1454.350, -89.084, 2462.130, -1135.040, 110.916},
    {"Marina", 647.712, -1577.590, -89.084, 807.922, -1416.250, 110.916},
    {"Richman", 72.648, -1404.970, -89.084, 225.165, -1235.070, 110.916},
    {"Vinewood", 647.712, -1416.250, -89.084, 787.461, -1227.280, 110.916},
    {"East Los Santos", 2222.560, -1628.530, -89.084, 2421.030, -1494.030, 110.916},
    {"Rodeo", 558.099, -1684.650, -89.084, 647.522, -1384.930, 110.916},
    {"Easter Tunnel", -1709.710, -833.034, -1.5, -1446.010, -730.118, 200.000},
    {"Rodeo", 466.223, -1385.070, -89.084, 647.522, -1235.070, 110.916},
    {"Redsands East", 1817.390, 2202.760, -89.084, 2011.940, 2342.830, 110.916},
    {"The Clown`s Pocket", 2162.390, 1783.230, -89.084, 2437.390, 1883.230, 110.916},
    {"Idlewood", 1971.660, -1852.870, -89.084, 2222.560, -1742.310, 110.916},
    {"Montgomery Intersection", 1546.650, 208.164, 0.000, 1745.830, 347.457, 200.000},
    {"Willowfield", 2089.000, -2235.840, -89.084, 2201.820, -1989.900, 110.916},
    {"Temple", 952.663, -1130.840, -89.084, 1096.470, -937.184, 110.916},
    {"Prickle Pine", 1848.400, 2553.490, -89.084, 1938.800, 2863.230, 110.916},
    {"Los Santos International", 1400.970, -2669.260, -39.084, 2189.820, -2597.260, 60.916},
    {"Garver Bridge", -1213.910, 950.022, -89.084, -1087.930, 1178.930, 110.916},
    {"Garver Bridge", -1339.890, 828.129, -89.084, -1213.910, 1057.040, 110.916},
    {"Kincaid Bridge", -1339.890, 599.218, -89.084, -1213.910, 828.129, 110.916},
    {"Kincaid Bridge", -1213.910, 721.111, -89.084, -1087.930, 950.022, 110.916},
    {"Verona Beach", 930.221, -2006.780, -89.084, 1073.220, -1804.210, 110.916},
    {"Verdant Bluffs", 1073.220, -2006.780, -89.084, 1249.620, -1842.270, 110.916},
    {"Vinewood", 787.461, -1130.840, -89.084, 952.604, -954.662, 110.916},
    {"Vinewood", 787.461, -1310.210, -89.084, 952.663, -1130.840, 110.916},
    {"Commerce", 1463.900, -1577.590, -89.084, 1667.960, -1430.870, 110.916},
    {"Market", 787.461, -1416.250, -89.084, 1072.660, -1310.210, 110.916},
    {"Rockshore West", 2377.390, 596.349, -89.084, 2537.390, 788.894, 110.916},
    {"Julius Thruway North", 2237.400, 2542.550, -89.084, 2498.210, 2663.170, 110.916},
    {"East Beach", 2632.830, -1668.130, -89.084, 2747.740, -1393.420, 110.916},
    {"Fallow Bridge", 434.341, 366.572, 0.000, 603.035, 555.680, 200.000},
    {"Willowfield", 2089.000, -1989.900, -89.084, 2324.000, -1852.870, 110.916},
    {"Chinatown", -2274.170, 578.396, -7.6, -2078.670, 744.170, 200.000},
    {"El Castillo del Diablo", -208.570, 2337.180, 0.000, 8.430, 2487.180, 200.000},
    {"Ocean Docks", 2324.000, -2145.100, -89.084, 2703.580, -2059.230, 110.916},
    {"Easter Bay Chemicals", -1132.820, -768.027, 0.000, -956.476, -578.118, 200.000},
    {"The Visage", 1817.390, 1703.230, -89.084, 2027.400, 1863.230, 110.916},
    {"Ocean Flats", -2994.490, -430.276, -1.2, -2831.890, -222.589, 200.000},
    {"Richman", 321.356, -860.619, -89.084, 687.802, -768.027, 110.916},
    {"Green Palms", 176.581, 1305.450, -3.0, 338.658, 1520.720, 200.000},
    {"Richman", 321.356, -768.027, -89.084, 700.794, -674.885, 110.916},
    {"Starfish Casino", 2162.390, 1883.230, -89.084, 2437.390, 2012.180, 110.916},
    {"East Beach", 2747.740, -1668.130, -89.084, 2959.350, -1498.620, 110.916},
    {"Jefferson", 2056.860, -1372.040, -89.084, 2281.450, -1210.740, 110.916},
    {"Downtown Los Santos", 1463.900, -1290.870, -89.084, 1724.760, -1150.870, 110.916},
    {"Downtown Los Santos", 1463.900, -1430.870, -89.084, 1724.760, -1290.870, 110.916},
    {"Garver Bridge", -1499.890, 696.442, -179.615, -1339.890, 925.353, 20.385},
    {"Julius Thruway South", 1457.390, 823.228, -89.084, 2377.390, 863.229, 110.916},
    {"East Los Santos", 2421.030, -1628.530, -89.084, 2632.830, -1454.350, 110.916},
    {"Greenglass College", 964.391, 1044.690, -89.084, 1197.390, 1203.220, 110.916},
    {"Las Colinas", 2747.740, -1120.040, -89.084, 2959.350, -945.035, 110.916},
    {"Mulholland", 737.573, -768.027, -89.084, 1142.290, -674.885, 110.916},
    {"Ocean Docks", 2201.820, -2730.880, -89.084, 2324.000, -2418.330, 110.916},
    {"East Los Santos", 2462.130, -1454.350, -89.084, 2581.730, -1135.040, 110.916},
    {"Ganton", 2222.560, -1722.330, -89.084, 2632.830, -1628.530, 110.916},
    {"Avispa Country Club", -2831.890, -430.276, -6.1, -2646.400, -222.589, 200.000},
    {"Willowfield", 1970.620, -2179.250, -89.084, 2089.000, -1852.870, 110.916},
    {"Esplanade North", -1982.320, 1274.260, -4.5, -1524.240, 1358.900, 200.000},
    {"The High Roller", 1817.390, 1283.230, -89.084, 2027.390, 1469.230, 110.916},
    {"Ocean Docks", 2201.820, -2418.330, -89.084, 2324.000, -2095.000, 110.916},
    {"Last Dime Motel", 1823.080, 596.349, -89.084, 1997.220, 823.228, 110.916},
    {"Bayside Marina", -2353.170, 2275.790, 0.000, -2153.170, 2475.790, 200.000},
    {"King`s", -2329.310, 458.411, -7.6, -1993.280, 578.396, 200.000},
    {"El Corona", 1692.620, -2179.250, -89.084, 1812.620, -1842.270, 110.916},
    {"Blackfield Chapel", 1375.600, 596.349, -89.084, 1558.090, 823.228, 110.916},
    {"The Pink Swan", 1817.390, 1083.230, -89.084, 2027.390, 1283.230, 110.916},
    {"Julius Thruway West", 1197.390, 1163.390, -89.084, 1236.630, 2243.230, 110.916},
    {"Los Flores", 2581.730, -1393.420, -89.084, 2747.740, -1135.040, 110.916},
    {"The Visage", 1817.390, 1863.230, -89.084, 2106.700, 2011.830, 110.916},
    {"Prickle Pine", 1938.800, 2624.230, -89.084, 2121.400, 2861.550, 110.916},
    {"Verona Beach", 851.449, -1804.210, -89.084, 1046.150, -1577.590, 110.916},
    {"Robada Intersection", -1119.010, 1178.930, -89.084, -862.025, 1351.450, 110.916},
    {"Linden Side", 2749.900, 943.235, -89.084, 2923.390, 1198.990, 110.916},
    {"Ocean Docks", 2703.580, -2302.330, -89.084, 2959.350, -2126.900, 110.916},
    {"Willowfield", 2324.000, -2059.230, -89.084, 2541.700, -1852.870, 110.916},
    {"King`s", -2411.220, 265.243, -9.1, -1993.280, 373.539, 200.000},
    {"Commerce", 1323.900, -1842.270, -89.084, 1701.900, -1722.260, 110.916},
    {"Mulholland", 1269.130, -768.027, -89.084, 1414.070, -452.425, 110.916},
    {"Marina", 647.712, -1804.210, -89.084, 851.449, -1577.590, 110.916},
    {"Battery Point", -2741.070, 1268.410, -4.5, -2533.040, 1490.470, 200.000},
    {"The Four Dragons Casino", 1817.390, 863.232, -89.084, 2027.390, 1083.230, 110.916},
    {"Blackfield", 964.391, 1203.220, -89.084, 1197.390, 1403.220, 110.916},
    {"Julius Thruway North", 1534.560, 2433.230, -89.084, 1848.400, 2583.230, 110.916},
    {"Yellow Bell Gol Course", 1117.400, 2723.230, -89.084, 1457.460, 2863.230, 110.916},
    {"Idlewood", 1812.620, -1602.310, -89.084, 2124.660, -1449.670, 110.916},
    {"Redsands West", 1297.470, 2142.860, -89.084, 1777.390, 2243.230, 110.916},
    {"Doherty", -2270.040, -324.114, -1.2, -1794.920, -222.589, 200.000},
    {"Hilltop Farm", 967.383, -450.390, -3.0, 1176.780, -217.900, 200.000},
    {"Las Barrancas", -926.130, 1398.730, -3.0, -719.234, 1634.690, 200.000},
    {"Pirates in Men`s Pants", 1817.390, 1469.230, -89.084, 2027.400, 1703.230, 110.916},
    {"City Hall", -2867.850, 277.411, -9.1, -2593.440, 458.411, 200.000},
    {"Avispa Country Club", -2646.400, -355.493, 0.000, -2270.040, -222.589, 200.000},
    {"The Strip", 2027.400, 863.229, -89.084, 2087.390, 1703.230, 110.916},
    {"Hashbury", -2593.440, -222.589, -1.0, -2411.220, 54.722, 200.000},
    {"Los Santos International", 1852.000, -2394.330, -89.084, 2089.000, -2179.250, 110.916},
    {"Whitewood Estates", 1098.310, 1726.220, -89.084, 1197.390, 2243.230, 110.916},
    {"Sherman Reservoir", -789.737, 1659.680, -89.084, -599.505, 1929.410, 110.916},
    {"El Corona", 1812.620, -2179.250, -89.084, 1970.620, -1852.870, 110.916},
    {"Downtown", -1700.010, 744.267, -6.1, -1580.010, 1176.520, 200.000},
    {"Foster Valley", -2178.690, -1250.970, 0.000, -1794.920, -1115.580, 200.000},
    {"Las Payasadas", -354.332, 2580.360, 2.0, -133.625, 2816.820, 200.000},
    {"Valle Ocultado", -936.668, 2611.440, 2.0, -715.961, 2847.900, 200.000},
    {"Blackfield Intersection", 1166.530, 795.010, -89.084, 1375.600, 1044.690, 110.916},
    {"Ganton", 2222.560, -1852.870, -89.084, 2632.830, -1722.330, 110.916},
    {"Easter Bay Airport", -1213.910, -730.118, 0.000, -1132.820, -50.096, 200.000},
    {"Redsands East", 1817.390, 2011.830, -89.084, 2106.700, 2202.760, 110.916},
    {"Esplanade East", -1499.890, 578.396, -79.615, -1339.890, 1274.260, 20.385},
    {"Caligula`s Palace", 2087.390, 1543.230, -89.084, 2437.390, 1703.230, 110.916},
    {"Royal Casino", 2087.390, 1383.230, -89.084, 2437.390, 1543.230, 110.916},
    {"Richman", 72.648, -1235.070, -89.084, 321.356, -1008.150, 110.916},
    {"Starfish Casino", 2437.390, 1783.230, -89.084, 2685.160, 2012.180, 110.916},
    {"Mulholland", 1281.130, -452.425, -89.084, 1641.130, -290.913, 110.916},
    {"Downtown", -1982.320, 744.170, -6.1, -1871.720, 1274.260, 200.000},
    {"Hankypanky Point", 2576.920, 62.158, 0.000, 2759.250, 385.503, 200.000},
    {"K.A.C.C. Military Fuels", 2498.210, 2626.550, -89.084, 2749.900, 2861.550, 110.916},
    {"Harry Gold Parkway", 1777.390, 863.232, -89.084, 1817.390, 2342.830, 110.916},
    {"Bayside Tunnel", -2290.190, 2548.290, -89.084, -1950.190, 2723.290, 110.916},
    {"Ocean Docks", 2324.000, -2302.330, -89.084, 2703.580, -2145.100, 110.916},
    {"Richman", 321.356, -1044.070, -89.084, 647.557, -860.619, 110.916},
    {"Randolph Industrial Estate", 1558.090, 596.349, -89.084, 1823.080, 823.235, 110.916},
    {"East Beach", 2632.830, -1852.870, -89.084, 2959.350, -1668.130, 110.916},
    {"Flint Water", -314.426, -753.874, -89.084, -106.339, -463.073, 110.916},
    {"Blueberry", 19.607, -404.136, 3.8, 349.607, -220.137, 200.000},
    {"Linden Station", 2749.900, 1198.990, -89.084, 2923.390, 1548.990, 110.916},
    {"Glen Park", 1812.620, -1350.720, -89.084, 2056.860, -1100.820, 110.916},
    {"Downtown", -1993.280, 265.243, -9.1, -1794.920, 578.396, 200.000},
    {"Redsands West", 1377.390, 2243.230, -89.084, 1704.590, 2433.230, 110.916},
    {"Richman", 321.356, -1235.070, -89.084, 647.522, -1044.070, 110.916},
    {"Gant Bridge", -2741.450, 1659.680, -6.1, -2616.400, 2175.150, 200.000},
    {"Lil` Probe Inn", -90.218, 1286.850, -3.0, 153.859, 1554.120, 200.000},
    {"Flint Intersection", -187.700, -1596.760, -89.084, 17.063, -1276.600, 110.916},
    {"Las Colinas", 2281.450, -1135.040, -89.084, 2632.740, -945.035, 110.916},
    {"Sobell Rail Yards", 2749.900, 1548.990, -89.084, 2923.390, 1937.250, 110.916},
    {"The Emerald Isle", 2011.940, 2202.760, -89.084, 2237.400, 2508.230, 110.916},
    {"El Castillo del Diablo", -208.570, 2123.010, -7.6, 114.033, 2337.180, 200.000},
    {"Santa Flora", -2741.070, 458.411, -7.6, -2533.040, 793.411, 200.000},
    {"Playa del Seville", 2703.580, -2126.900, -89.084, 2959.350, -1852.870, 110.916},
    {"Market", 926.922, -1577.590, -89.084, 1370.850, -1416.250, 110.916},
    {"Queens", -2593.440, 54.722, 0.000, -2411.220, 458.411, 200.000},
    {"Pilson Intersection", 1098.390, 2243.230, -89.084, 1377.390, 2507.230, 110.916},
    {"Spinybed", 2121.400, 2663.170, -89.084, 2498.210, 2861.550, 110.916},
    {"Pilgrim", 2437.390, 1383.230, -89.084, 2624.400, 1783.230, 110.916},
    {"Blackfield", 964.391, 1403.220, -89.084, 1197.390, 1726.220, 110.916},
    {"'The Big Ear'", -410.020, 1403.340, -3.0, -137.969, 1681.230, 200.000},
    {"Dillimore", 580.794, -674.885, -9.5, 861.085, -404.790, 200.000},
    {"El Quebrados", -1645.230, 2498.520, 0.000, -1372.140, 2777.850, 200.000},
    {"Esplanade North", -2533.040, 1358.900, -4.5, -1996.660, 1501.210, 200.000},
    {"Easter Bay Airport", -1499.890, -50.096, -1.0, -1242.980, 249.904, 200.000},
    {"Fisher`s Lagoon", 1916.990, -233.323, -100.000, 2131.720, 13.800, 200.000},
    {"Mulholland", 1414.070, -768.027, -89.084, 1667.610, -452.425, 110.916},
    {"East Beach", 2747.740, -1498.620, -89.084, 2959.350, -1120.040, 110.916},
    {"San Andreas Sound", 2450.390, 385.503, -100.000, 2759.250, 562.349, 200.000},
    {"Shady Creeks", -2030.120, -2174.890, -6.1, -1820.640, -1771.660, 200.000},
    {"Market", 1072.660, -1416.250, -89.084, 1370.850, -1130.850, 110.916},
    {"Rockshore West", 1997.220, 596.349, -89.084, 2377.390, 823.228, 110.916},
    {"Prickle Pine", 1534.560, 2583.230, -89.084, 1848.400, 2863.230, 110.916},
    {"Easter Basin", -1794.920, -50.096, -1.04, -1499.890, 249.904, 200.000},
    {"Leafy Hollow", -1166.970, -1856.030, 0.000, -815.624, -1602.070, 200.000},
    {"LVA Freight Depot", 1457.390, 863.229, -89.084, 1777.400, 1143.210, 110.916},
    {"Prickle Pine", 1117.400, 2507.230, -89.084, 1534.560, 2723.230, 110.916},
    {"Blueberry", 104.534, -220.137, 2.3, 349.607, 152.236, 200.000},
    {"El Castillo del Diablo", -464.515, 2217.680, 0.000, -208.570, 2580.360, 200.000},
    {"Downtown", -2078.670, 578.396, -7.6, -1499.890, 744.267, 200.000},
    {"Rockshore East", 2537.390, 676.549, -89.084, 2902.350, 943.235, 110.916},
    {"San Fierro Bay", -2616.400, 1501.210, -3.0, -1996.660, 1659.680, 200.000},
    {"Paradiso", -2741.070, 793.411, -6.1, -2533.040, 1268.410, 200.000},
    {"The Camel`s Toe", 2087.390, 1203.230, -89.084, 2640.400, 1383.230, 110.916},
    {"Old Venturas Strip", 2162.390, 2012.180, -89.084, 2685.160, 2202.760, 110.916},
    {"Juniper Hill", -2533.040, 578.396, -7.6, -2274.170, 968.369, 200.000},
    {"Juniper Hollow", -2533.040, 968.369, -6.1, -2274.170, 1358.900, 200.000},
    {"Roca Escalante", 2237.400, 2202.760, -89.084, 2536.430, 2542.550, 110.916},
    {"Julius Thruway East", 2685.160, 1055.960, -89.084, 2749.900, 2626.550, 110.916},
    {"Verona Beach", 647.712, -2173.290, -89.084, 930.221, -1804.210, 110.916},
    {"Foster Valley", -2178.690, -599.884, -1.2, -1794.920, -324.114, 200.000},
    {"Arco del Oeste", -901.129, 2221.860, 0.000, -592.090, 2571.970, 200.000},
    {"Fallen Tree", -792.254, -698.555, -5.3, -452.404, -380.043, 200.000},
    {"The Farm", -1209.670, -1317.100, 114.981, -908.161, -787.391, 251.981},
    {"The Sherman Dam", -968.772, 1929.410, -3.0, -481.126, 2155.260, 200.000},
    {"Esplanade North", -1996.660, 1358.900, -4.5, -1524.240, 1592.510, 200.000},
    {"Financial", -1871.720, 744.170, -6.1, -1701.300, 1176.420, 300.000},
    {"Garcia", -2411.220, -222.589, -1.14, -2173.040, 265.243, 200.000},
    {"Montgomery", 1119.510, 119.526, -3.0, 1451.400, 493.323, 200.000},
    {"Creek", 2749.900, 1937.250, -89.084, 2921.620, 2669.790, 110.916},
    {"Los Santos International", 1249.620, -2394.330, -89.084, 1852.000, -2179.250, 110.916},
    {"Santa Maria Beach", 72.648, -2173.290, -89.084, 342.648, -1684.650, 110.916},
    {"Mulholland Intersection", 1463.900, -1150.870, -89.084, 1812.620, -768.027, 110.916},
    {"Angel Pine", -2324.940, -2584.290, -6.1, -1964.220, -2212.110, 200.000},
    {"Verdant Meadows", 37.032, 2337.180, -3.0, 435.988, 2677.900, 200.000},
    {"Octane Springs", 338.658, 1228.510, 0.000, 664.308, 1655.050, 200.000},
    {"Come-A-Lot", 2087.390, 943.235, -89.084, 2623.180, 1203.230, 110.916},
    {"Redsands West", 1236.630, 1883.110, -89.084, 1777.390, 2142.860, 110.916},
    {"Santa Maria Beach", 342.648, -2173.290, -89.084, 647.712, -1684.650, 110.916},
    {"Verdant Bluffs", 1249.620, -2179.250, -89.084, 1692.620, -1842.270, 110.916},
    {"Las Venturas Airport", 1236.630, 1203.280, -89.084, 1457.370, 1883.110, 110.916},
    {"Flint Range", -594.191, -1648.550, 0.000, -187.700, -1276.600, 200.000},
    {"Verdant Bluffs", 930.221, -2488.420, -89.084, 1249.620, -2006.780, 110.916},
    {"Palomino Creek", 2160.220, -149.004, 0.000, 2576.920, 228.322, 200.000},
    {"Ocean Docks", 2373.770, -2697.090, -89.084, 2809.220, -2330.460, 110.916},
    {"Easter Bay Airport", -1213.910, -50.096, -4.5, -947.980, 578.396, 200.000},
    {"Whitewood Estates", 883.308, 1726.220, -89.084, 1098.310, 2507.230, 110.916},
    {"Calton Heights", -2274.170, 744.170, -6.1, -1982.320, 1358.900, 200.000},
    {"Easter Basin", -1794.920, 249.904, -9.1, -1242.980, 578.396, 200.000},
    {"Los Santos Inlet", -321.744, -2224.430, -89.084, 44.615, -1724.430, 110.916},
    {"Doherty", -2173.040, -222.589, -1.0, -1794.920, 265.243, 200.000},
    {"Mount Chiliad", -2178.690, -2189.910, -47.917, -2030.120, -1771.660, 576.083},
    {"Fort Carson", -376.233, 826.326, -3.0, 123.717, 1220.440, 200.000},
    {"Foster Valley", -2178.690, -1115.580, 0.000, -1794.920, -599.884, 200.000},
    {"Ocean Flats", -2994.490, -222.589, -1.0, -2593.440, 277.411, 200.000},
    {"Fern Ridge", 508.189, -139.259, 0.000, 1306.660, 119.526, 200.000},
    {"Bayside", -2741.070, 2175.150, 0.000, -2353.170, 2722.790, 200.000},
    {"Las Venturas Airport", 1457.370, 1203.280, -89.084, 1777.390, 1883.110, 110.916},
    {"Blueberry Acres", -319.676, -220.137, 0.000, 104.534, 293.324, 200.000},
    {"Palisades", -2994.490, 458.411, -6.1, -2741.070, 1339.610, 200.000},
    {"North Rock", 2285.370, -768.027, 0.000, 2770.590, -269.740, 200.000},
    {"Hunter Quarry", 337.244, 710.840, -115.239, 860.554, 1031.710, 203.761},
    {"Los Santos International", 1382.730, -2730.880, -89.084, 2201.820, -2394.330, 110.916},
    {"Missionary Hill", -2994.490, -811.276, 0.000, -2178.690, -430.276, 200.000},
    {"San Fierro Bay", -2616.400, 1659.680, -3.0, -1996.660, 2175.150, 200.000},
    {"Restricted Area", -91.586, 1655.050, -50.000, 421.234, 2123.010, 250.000},
    {"Mount Chiliad", -2997.470, -1115.580, -47.917, -2178.690, -971.913, 576.083},
    {"Mount Chiliad", -2178.690, -1771.660, -47.917, -1936.120, -1250.970, 576.083},
    {"Easter Bay Airport", -1794.920, -730.118, -3.0, -1213.910, -50.096, 200.000},
    {"The Panopticon", -947.980, -304.320, -1.1, -319.676, 327.071, 200.000},
    {"Shady Creeks", -1820.640, -2643.680, -8.0, -1226.780, -1771.660, 200.000},
    {"Back o Beyond", -1166.970, -2641.190, 0.000, -321.744, -1856.030, 200.000},
    {"Mount Chiliad", -2994.490, -2189.910, -47.917, -2178.690, -1115.580, 576.083},
    {"Tierra Robada", -1213.910, 596.349, -242.990, -480.539, 1659.680, 900.000},
    {"Flint County", -1213.910, -2892.970, -242.990, 44.615, -768.027, 900.000},
    {"Whetstone", -2997.470, -2892.970, -242.990, -1213.910, -1115.580, 900.000},
    {"Bone County", -480.539, 596.349, -242.990, 869.461, 2993.870, 900.000},
    {"Tierra Robada", -2997.470, 1659.680, -242.990, -480.539, 2993.870, 900.000},
    {"San Fierro", -2997.470, -1115.580, -242.990, -1213.910, 1659.680, 900.000},
    {"Las Venturas", 869.461, 596.349, -242.990, 2997.060, 2993.870, 900.000},
    {"Red County", -1213.910, -768.027, -242.990, 2997.060, 596.349, 900.000},
    {"Los Santos", 44.615, -2892.970, -242.990, 2997.060, -768.027, 900.000}}

    for i, v in ipairs(streets) do
        if (x >= v[2]) and (y >= v[3]) and (z >= v[4]) and (x <= v[5]) and (y <= v[6]) and (z <= v[7]) then
            return v[1]
        end
    end

    return "Неизвестно"
end

function patch_samp_time_set(enable)
	if enable and default == nil then
		default = readMemory(sampGetBase() + 0x9C0A0, 4, true)
		writeMemory(sampGetBase() + 0x9C0A0, 4, 0x000008C2, true)
	elseif enable == false and default then
		writeMemory(sampGetBase() + 0x9C0A0, 4, default, true)
		default = nil
	end
end

function reconnect(delay, ip)
	if type(delay) == ("number") and ip == nil then
		lua_thread.create(function()
			local wdelay = delay * 1000
			sampDisconnectWithReason(1)
			local startTime = os.clock()
			global_reconnect_status = true
			while os.clock() - startTime < delay do wait(0) end
			global_reconnect_status = false
			sampSetGamestate(1)
		end)
	elseif type(delay) == ("number") and type(ip) == ("string") then
		lua_thread.create(function()
			if string.match(ip, "(%S+):(%d+)") then
				local ipadress, port = string.match(ip, "(.+):(%d+)")
				local port = tonumber(port)
				local wdelay = delay * 1000
				local startTime = os.clock()
				global_reconnect_status = true
				while os.clock() - startTime < delay do wait(0) end
				global_reconnect_status = false
				sampConnectToServer(ipadress, port)
			end
		end)
	end
end

function sampGetColorByPlayerId(id)
	return argb_to_hex(sampGetPlayerColor(id))
end

function argb_to_hex(number)
    return bit.tohex(number, 6)
end

function apply_custom_style()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
	local ImVec2 = imgui.ImVec2

	style.WindowBorderSize = 0.0

	style.WindowRounding         = 10.0
	style.ChildRounding          = 10.0
	style.WindowTitleAlign       = ImVec2(0.5, 0.5)
	style.FrameRounding          = 5.0
	style.ItemSpacing            = ImVec2(10, 5)
	style.ScrollbarSize          = 1
	style.ScrollbarRounding      = 0
	style.GrabMinSize            = 2.0
	style.GrabRounding           = 10.0
	style.WindowPadding          = ImVec2(10, 10)
	style.FramePadding           = ImVec2(5, 4)
	style.DisplayWindowPadding   = ImVec2(27, 27)
	style.DisplaySafeAreaPadding = ImVec2(5, 5)
	style.ButtonTextAlign        = ImVec2(0.5, 0.5)
	style.IndentSpacing          = 12.0
	style.Alpha                  = 1.0

	if configuration["MAIN"]["settings"]["customization"] then
		for k, v in pairs(configuration["MAIN"]["customization"]) do
			if v then colors[clr[k]] = ImVec4(v["r"], v["g"], v["b"], v["a"]) end
		end
	else
		colors[clr.Button]               = ImVec4(0.13, 0.75, 0.55, 0.40)
		colors[clr.ButtonHovered]        = ImVec4(0.13, 0.75, 0.75, 0.60)
		colors[clr.ButtonActive]         = ImVec4(0.13, 0.75, 1.00, 0.80)
		colors[clr.Header]               = ImVec4(0.13, 0.75, 0.55, 0.40)
		colors[clr.HeaderHovered]        = ImVec4(0.13, 0.75, 0.75, 0.60)
		colors[clr.HeaderActive]         = ImVec4(0.13, 0.75, 1.00, 0.80)
		colors[clr.Separator]            = ImVec4(0.13, 0.75, 0.55, 0.40)
		colors[clr.SeparatorHovered]     = ImVec4(0.13, 0.75, 0.75, 0.60)
		colors[clr.SeparatorActive]      = ImVec4(0.13, 0.75, 1.00, 0.80)
		colors[clr.SliderGrab]           = ImVec4(0.13, 0.75, 0.75, 0.80)
		colors[clr.SliderGrabActive]     = ImVec4(0.13, 0.75, 1.00, 0.80)
	end

	colors[clr.ChildBg]              = ImVec4(0.12, 0.12, 0.12, 1.00)

	colors[clr.FrameBg]              = ImVec4(0.44, 0.44, 0.44, 0.10)
	colors[clr.FrameBgHovered]       = ImVec4(0.57, 0.57, 0.57, 0.20)
	colors[clr.FrameBgActive]        = ImVec4(0.76, 0.76, 0.76, 0.30)

	colors[clr.Text]                 = ImVec4(1.00, 1.00, 1.00, 1.00)
	colors[clr.TextDisabled]         = ImVec4(0.50, 0.50, 0.50, 1.00)
	colors[clr.WindowBg]             = ImVec4(0.06, 0.06, 0.06, 0.98)
	colors[clr.PopupBg]              = ImVec4(0.08, 0.08, 0.08, 0.94)
	colors[clr.Border]               = ImVec4(0.43, 0.43, 0.50, 0.50)
	colors[clr.BorderShadow]         = ImVec4(0.00, 0.00, 0.00, 0.00)
	colors[clr.TitleBg]              = ImVec4(0.04, 0.04, 0.04, 1.00)
	colors[clr.TitleBgActive]        = ImVec4(0.16, 0.16, 0.16, 1.00)
	colors[clr.TitleBgCollapsed]     = ImVec4(0.00, 0.00, 0.00, 0.60)
	colors[clr.CheckMark]            = ImVec4(0.13, 0.75, 0.55, 0.80)
	colors[clr.MenuBarBg]            = ImVec4(0.14, 0.14, 0.14, 1.00)
	colors[clr.ScrollbarBg]          = ImVec4(0.02, 0.02, 0.02, 0.53)
	colors[clr.ScrollbarGrab]        = ImVec4(0.31, 0.31, 0.31, 1.00)
	colors[clr.ScrollbarGrabHovered] = ImVec4(0.41, 0.41, 0.41, 1.00)
	colors[clr.ScrollbarGrabActive]  = ImVec4(0.51, 0.51, 0.51, 1.00)
	colors[clr.ResizeGrip]           = ImVec4(0.13, 0.75, 0.55, 0.40)
	colors[clr.ResizeGripHovered]    = ImVec4(0.13, 0.75, 0.75, 0.60)
	colors[clr.ResizeGripActive]     = ImVec4(0.13, 0.75, 1.00, 0.80)
	colors[clr.PlotLines]            = ImVec4(0.61, 0.61, 0.61, 1.00)
	colors[clr.PlotLinesHovered]     = ImVec4(1.00, 0.43, 0.35, 1.00)
	colors[clr.PlotHistogram]        = ImVec4(0.90, 0.70, 0.00, 1.00)
	colors[clr.PlotHistogramHovered] = ImVec4(1.00, 0.60, 0.00, 1.00)
	colors[clr.TextSelectedBg]       = ImVec4(0.26, 0.59, 0.98, 0.35)
end

function imgui.Center(x)
	imgui.SetCursorPosX(imgui.GetWindowWidth() / 2 - x / 2)
end

function imgui.CenterText(text)
    imgui.SetCursorPosX(imgui.GetWindowWidth() / 2 - imgui.CalcTextSize(text).x / 2)
	imgui.Text(text)
end

function imgui.CenterColumn(x)
	imgui.SetCursorPosX((imgui.GetColumnOffset() + (imgui.GetColumnWidth() / 2)) - x / 2)
end

function imgui.CenterColumnText(text)
    imgui.SetCursorPosX((imgui.GetColumnOffset() + (imgui.GetColumnWidth() / 2)) - imgui.CalcTextSize(text).x / 2)
    imgui.Text(text)
end

function imgui.CustomButton(str_id, size, color)
	if not size then size = imgui.ImVec2(0, 0) end
	if not color then color = imgui.ImVec4(0, 0, 0, 0) end

    local clr = imgui.Col
    if color == 0 then
    	imgui.PushStyleColor(clr.Button, imgui.ImVec4(0, 0, 0, 0))
    	imgui.PushStyleColor(clr.ButtonActive, imgui.ImVec4(0, 0, 0, 0))
    	imgui.PushStyleColor(clr.ButtonHovered, imgui.ImVec4(0.1, 0.1, 0.1, 1.0))
	    local result = imgui.Button(str_id, size)
	    imgui.PopStyleColor(3)
	    return result
    else
	    imgui.PushStyleColor(clr.Button, color)
	    local result = imgui.Button(str_id, size)
	    imgui.PopStyleColor(1)
	    return result
	end
end

function imgui.Hint(str_id, hint_text, color, no_center)
    color = color or imgui.GetStyle().Colors[imgui.Col.PopupBg]
    local p_orig = imgui.GetCursorPos()
    local hovered = imgui.IsItemHovered()
    imgui.SameLine(nil, 0)

    local animTime = 0.2
    local show = true

    if not POOL_HINTS then POOL_HINTS = {} end
    if not POOL_HINTS[str_id] then
        POOL_HINTS[str_id] = {
            status = false,
            timer = 0
        }
    end

    if hovered then
        for k, v in pairs(POOL_HINTS) do
            if k ~= str_id and os.clock() - v.timer <= animTime  then
                show = false
            end
        end
    end

    if show and POOL_HINTS[str_id].status ~= hovered then
        POOL_HINTS[str_id].status = hovered
        POOL_HINTS[str_id].timer = os.clock()
    end

    local getContrastColor = function(col)
        local luminance = 1 - (0.299 * col.x + 0.587 * col.y + 0.114 * col.z)
        return luminance < 0.5 and imgui.ImVec4(0, 0, 0, 1) or imgui.ImVec4(1, 1, 1, 1)
    end

    local rend_window = function(alpha)
        local size = imgui.GetItemRectSize()
        local scrPos = imgui.GetCursorScreenPos()
        local DL = imgui.GetWindowDrawList()
        local center = imgui.ImVec2( scrPos.x - (size.x / 2), scrPos.y + (size.y / 2) - (alpha * 4) + 10 )
        local a = imgui.ImVec2( center.x - 7, center.y - size.y - 3 )
        local b = imgui.ImVec2( center.x + 7, center.y - size.y - 3)
        local c = imgui.ImVec2( center.x, center.y - size.y + 3 )
        local col = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(color.x, color.y, color.z, alpha))

        DL:AddTriangleFilled(a, b, c, col)
        imgui.SetNextWindowPos(imgui.ImVec2(center.x, center.y - size.y - 3), imgui.Cond.Always, imgui.ImVec2(0.5, 1.0))
        imgui.PushStyleColor(imgui.Col.PopupBg, color)
        imgui.PushStyleColor(imgui.Col.Border, color)
        imgui.PushStyleColor(imgui.Col.Text, getContrastColor(color))
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
        imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 6)
        imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, alpha)

        local max_width = function(text)
            local result = 0
            for line in text:gmatch('[^\n]+') do
                local len = imgui.CalcTextSize(line).x
                if len > result then
                    result = len
                end
            end
            return result
        end

        local hint_width = max_width(hint_text) + (imgui.GetStyle().WindowPadding.x * 2)
        imgui.SetNextWindowSize(imgui.ImVec2(hint_width, -1), imgui.Cond.Always)
        imgui.Begin('##' .. str_id, _, imgui.WindowFlags.Tooltip + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoTitleBar)
            for line in hint_text:gmatch('[^\n]+') do
                if no_center then
                    imgui.Text(line)
                else
                    imgui.SetCursorPosX((hint_width - imgui.CalcTextSize(line).x) / 2)
                    imgui.Text(line)
                end
            end
        imgui.End()

        imgui.PopStyleVar(3)
        imgui.PopStyleColor(3)
    end

    if show then
        local between = os.clock() - POOL_HINTS[str_id].timer
        if between <= animTime then
            local s = function(f)
                return f < 0.0 and 0.0 or (f > 1.0 and 1.0 or f)
            end
            local alpha = hovered and s(between / animTime) or s(1.00 - between / animTime)
            rend_window(alpha)
        elseif hovered then
            rend_window(1.00)
        end
    end

    imgui.SetCursorPos(p_orig)
end

function isKeyCheckAvailable()
	if not isSampfuncsLoaded() then return not isPauseMenuActive() end
	local result = not isSampfuncsConsoleActive() and not isPauseMenuActive()
	if isSampLoaded() and isSampAvailable() then result = result and not sampIsChatInputActive() and not sampIsDialogActive() end
	return result
end

function sampGetPlayerIdByNickname(nickname)
	if type(nickname) == ("string") then
		for player_id = 0, 1000 do
			if isPlayerConnected(player_id) then
				if sampGetPlayerNickname(player_id) == nickname then return player_id end
			end
		end
	end
end

function sampGetNearestDriver()
	local output_player, output_vehicle
	local maximum_distance = 55

	if isCharSittingInAnyCar(playerPed) then
		local player_vehicle = storeCarCharIsInNoSave(playerPed)

		for result, ped in ipairs(getAllChars()) do
			if doesCharExist(ped) and isCharOnScreen(ped) then
				if isCharSittingInAnyCar(ped) and not isCharInAnyPoliceVehicle(ped) then
					local vehicle = storeCarCharIsInNoSave(ped)
					if vehicle ~= player_vehicle then
						if getDriverOfCar(vehicle) == ped then
							local distance = getDistanceToPlayer(ped)
							if distance < maximum_distance then
								local result, player_id = sampGetPlayerIdByCharHandle(ped)
								maximum_distance = distance
								output_player, output_vehicle = player_id, getCarModel(vehicle)
							end
						end
					end
				end
			end
		end

		if not output_player then
			for result, ped in ipairs(getAllChars()) do
				if doesCharExist(ped) and isCharOnScreen(ped) then
					if isCharSittingInAnyCar(ped) then
						local vehicle = storeCarCharIsInNoSave(ped)
						if vehicle ~= player_vehicle then
							if getDriverOfCar(vehicle) == ped then
								local distance = getDistanceToPlayer(ped)
								if distance < maximum_distance then
									local result, player_id = sampGetPlayerIdByCharHandle(ped)
									maximum_distance = distance
									output_player, output_vehicle = player_id, getCarModel(vehicle)
								end
							end
						end
					end
				end
			end
		end
	end

	return output_player, output_vehicle
end

function stroboscopes(adress, ptr, _1, _2, _3, _4)
	if not isCharInAnyCar(playerPed) or isCharOnAnyBike(playerPed) then return end

	if not b_stroboscopes then
		forceCarLights(storeCarCharIsInNoSave(playerPed), 0)
		callMethod(7086336, ptr, 2, 0, 1, 3)
		callMethod(7086336, ptr, 2, 0, 0, 0)
		callMethod(7086336, ptr, 2, 0, 1, 0)
		markCarAsNoLongerNeeded(storeCarCharIsInNoSave(playerPed))
		return
	end

	callMethod(adress, ptr, _1, _2, _3, _4)
end

function getSerialNumber()
	local ffi = require("ffi")
	ffi.cdef[[
	int __stdcall GetVolumeInformationA(
		const char* lpRootPathName,
		char* lpVolumeNameBuffer,
		uint32_t nVolumeNameSize,
		uint32_t* lpVolumeSerialNumber,
		uint32_t* lpMaximumComponentLength,
		uint32_t* lpFileSystemFlags,
		char* lpFileSystemNameBuffer,
		uint32_t nFileSystemNameSize
	);
	]]
	local serial = ffi.new("unsigned long[1]", 0)
	ffi.C.GetVolumeInformationA(nil, nil, 0, serial, nil, nil, nil, 0)
	serial = serial[0]

	return serial
end

function urlencode(str)
   if (str) then
      str = string.gsub (str, "\n", "\r\n")
      str = string.gsub (str, "([^%w ])",
         function (c) return string.format ("%%%02X", string.byte(c)) end)
      str = string.gsub (str, " ", "+")
   end
   return str
end

function displaying_inline_sections(input, last)
	for k, v in pairs(input) do
		if k == "position" then
			imgui.CustomButton(tostring(string.upper(k))) imgui.SameLine()
			if imgui.Button(u8"Поставить метку") then
				create_map_marker({ v["x"], v["y"], v["z"] })
				local x, y, z = getCharCoordinates(playerPed)
				local distance = getDistanceBetweenCoords3d(x, y, z, v["x"], v["y"], v["z"])
				chat(string.format("На вашем радаре отмечен {HEX}маркер{}, расстояние до него {HEX}%s{} м.", math.floor(distance)))
			end
		elseif k == "time" then
			imgui.CustomButton(tostring(string.upper(k))) imgui.SameLine()
			if imgui.Button(os.date("%d.%m.%Y, %H:%M:%S", v)) then
				setClipboardText(os.date("%d.%m.%Y, %H:%M:%S", v))
			end
		else
			if type(v) == "table" then
				if imgui.TreeNodeStr(string.format(u8"Таблица '%s'", k)) then
					displaying_inline_sections(v, k)
					imgui.TreePop()
				end
			else
				imgui.CustomButton(tostring(string.upper(k))) imgui.SameLine()
				if imgui.Button(tostring(v)) then
					setClipboardText(tostring(v))
				end
			end
		end
	end
end

function displaying_quick_menu(input, close) -- original author DonHomka
	local result

	local style = imgui.GetStyle()
	local minimal_radius = 60.0
	local maximum_radius = 200.0
	local minimum_interact_radius = 20.0

	local DrawList = imgui.GetWindowDrawList()
	local IM_PI = 3.14159265358979323846
	local center = imgui.ImVec2(w / 2, h / 2)
	local drag_delta = imgui.ImVec2(imgui.GetIO().MousePos["x"] - center["x"], imgui.GetIO().MousePos["y"] - center["y"])
	local drag_distance2 = drag_delta["x"] * drag_delta["x"] + drag_delta["y"] * drag_delta["y"]
	local count = #input

	DrawList:PushClipRectFullScreen()
	DrawList:PathArcTo(center, (minimal_radius + maximum_radius)*0.5, 0.0, IM_PI*2.0*0.98, 64)
	DrawList:PathStroke(0x4c010101, true, maximum_radius - minimal_radius)

	local input_arc_span = 2 * IM_PI / count
	local drag_angle = math.atan2(drag_delta["y"], drag_delta["x"])

	for index = 1, count do
		local input_label = input[index].title
		local inner_spacing = style["ItemInnerSpacing"]["x"] / minimal_radius / 2
		local input_inner_angle_minimum = input_arc_span * (index - 0.5 + inner_spacing)
		local input_inner_angle_maximum = input_arc_span * (index + 0.5 - inner_spacing)
		local input_outer_angle_minimum = input_arc_span * (index - 0.5 + inner_spacing * (minimal_radius / maximum_radius))
		local input_outer_angle_maximum = input_arc_span * (index + 0.5 - inner_spacing * (minimal_radius / maximum_radius))

		local hovered = false
		while (drag_angle - input_inner_angle_minimum) < 0.0 do
			drag_angle = drag_angle + 2.0 * IM_PI
		end

		while (drag_angle - input_inner_angle_minimum) > (2.0 * IM_PI) do
			drag_angle = drag_angle - 2.0 * IM_PI
		end

		if drag_distance2 >= (minimum_interact_radius * minimum_interact_radius) then
			if drag_angle >= input_inner_angle_minimum and drag_angle < input_inner_angle_maximum then
				hovered = true
			end
		end

		local color = input[index]["color"] or configuration["MAIN"]["settings"]["t_script_color"]

		local arc_segments = (64 * input_arc_span / (2 * IM_PI)) + 1
		DrawList:PathArcTo(center, maximum_radius - style["ItemInnerSpacing"]["x"], input_outer_angle_minimum, input_outer_angle_maximum, arc_segments)
		DrawList:PathArcTo(center, minimal_radius + style["ItemInnerSpacing"]["x"], input_inner_angle_maximum, input_inner_angle_minimum, arc_segments)
		DrawList:PathFillConvex(hovered and color or 0xFF232323)

		local text_size = imgui.CalcTextSize(input_label)
		local text_pos = imgui.ImVec2(
			center["x"] + math.cos((input_inner_angle_minimum + input_inner_angle_maximum) * 0.5) * (minimal_radius + maximum_radius) * 0.5 - text_size["x"] * 0.5 + 1,
			center["y"] + math.sin((input_inner_angle_minimum + input_inner_angle_maximum) * 0.5) * (minimal_radius + maximum_radius) * 0.5 - text_size["y"] * 0.5 + 1)
		DrawList:AddText(text_pos, 0xFFFFFFFF, input_label)

		if hovered then
			if imgui.IsMouseClicked(0) then
				if input[index] and input[index]["callback"] then
					input[index]["callback"]()
					result = true
				end
			end
		end
	end

	DrawList:PopClipRect()

	if result then return result end
end

function register_quick_menu()
	quick_menu_list = {}
	for index, value in ipairs(configuration["MAIN"]["quick_menu"]) do
		quick_menu_list[index] = {}
		quick_menu_list[index]["title"] = value["title"]
		if tonumber(value["callback"]) then
			quick_menu_list[index]["callback"] = function()
				lua_thread.create(function() command_handler("main", value["callback"], targeting_player) end)
			end
		else
			quick_menu_list[index]["callback"] = function() _G[value["callback"]](targeting_player) end
		end
	end

	quick_tags_menu = {}
	for index, value in ipairs(abbreviated_codes) do
		quick_tags_menu[index] = {
			["title"] = value[3],
			["callback"] = function()
				if global_radio == "r" then
					command_r(value[1])
				else
					command_f(value[2])
				end
			end
		}
	end
end

function sum_format(a)
    local b, e = ("%d"):format(a):gsub("^%-", "")
    local c = b:reverse():gsub("%d%d%d", "%1.")
    local d = c:reverse():gsub("^%.", "")
    return (e == 1 and "-" or "")..d
end

local lower, sub, char, upper = string.lower, string.sub, string.char, string.upper
local concat = table.concat

-- initialization table
local lu_rus, ul_rus = {}, {}
for i = 192, 223 do
    local A, a = char(i), char(i + 32)
    ul_rus[A] = a
    lu_rus[a] = A
end
local E, e = char(168), char(184)
ul_rus[E] = e
lu_rus[e] = E

function string.nlower(s)
    s = lower(s)
    local len, res = #s, {}
    for i = 1, len do
        local ch = sub(s, i, i)
        res[i] = ul_rus[ch] or ch
    end
    return concat(res)
end

function string.nupper(s)
    s = upper(s)
    local len, res = #s, {}
    for i = 1, len do
        local ch = sub(s, i, i)
        res[i] = lu_rus[ch] or ch
    end
    return concat(res)
end

function header_button(bool, str_id) -- https://www.blast.hk/threads/13380/post-814506
    local DL = imgui.GetWindowDrawList()
    local ToU32 = imgui.ColorConvertFloat4ToU32
    local result = false
    local label = string.gsub(str_id, "##.*$", "")
    local duration = { 0.5, 0.3 }
    local cols = {
        idle = imgui.GetStyle().Colors[imgui.Col.TextDisabled],
        hovr = imgui.GetStyle().Colors[imgui.Col.Text],
        slct = imgui.GetStyle().Colors[imgui.Col.ButtonActive]
    }

    if not AI_HEADERBUT then AI_HEADERBUT = {} end
     if not AI_HEADERBUT[str_id] then
        AI_HEADERBUT[str_id] = {
            color = bool and cols.slct or cols.idle,
            clock = os.clock() + duration[1],
            h = {
                state = bool,
                alpha = bool and 1.00 or 0.00,
                clock = os.clock() + duration[2],
            }
        }
    end
    local pool = AI_HEADERBUT[str_id]

    local degrade = function(before, after, start_time, duration)
        local result = before
        local timer = os.clock() - start_time
        if timer >= 0.00 then
            local offs = {
                x = after.x - before.x,
                y = after.y - before.y,
                z = after.z - before.z,
                w = after.w - before.w
            }

            result.x = result.x + ( (offs.x / duration) * timer )
            result.y = result.y + ( (offs.y / duration) * timer )
            result.z = result.z + ( (offs.z / duration) * timer )
            result.w = result.w + ( (offs.w / duration) * timer )
        end
        return result
    end

    local pushFloatTo = function(p1, p2, clock, duration)
        local result = p1
        local timer = os.clock() - clock
        if timer >= 0.00 then
            local offs = p2 - p1
            result = result + ((offs / duration) * timer)
        end
        return result
    end

    local set_alpha = function(color, alpha)
        return imgui.ImVec4(color.x, color.y, color.z, alpha or 1.00)
    end

    imgui.BeginGroup()
        local pos = imgui.GetCursorPos()
        local p = imgui.GetCursorScreenPos()

        imgui.TextColored(pool.color, label)
        local s = imgui.GetItemRectSize()
        local hovered = imgui.IsItemHovered()
        local clicked = imgui.IsItemClicked()

        if pool.h.state ~= hovered and not bool then
            pool.h.state = hovered
            pool.h.clock = os.clock()
        end

        if clicked then
            pool.clock = os.clock()
            result = true
        end

        if os.clock() - pool.clock <= duration[1] then
            pool.color = degrade(
                imgui.ImVec4(pool.color),
                bool and cols.slct or (hovered and cols.hovr or cols.idle),
                pool.clock,
                duration[1]
            )
        else
            pool.color = bool and cols.slct or (hovered and cols.hovr or cols.idle)
        end

        if pool.h.clock ~= nil then
            if os.clock() - pool.h.clock <= duration[2] then
                pool.h.alpha = pushFloatTo(
                    pool.h.alpha,
                    pool.h.state and 1.00 or 0.00,
                    pool.h.clock,
                    duration[2]
                )
            else
                pool.h.alpha = pool.h.state and 1.00 or 0.00
                if not pool.h.state then
                    pool.h.clock = nil
                end
            end

            local max = s.x / 2
            local Y = p.y + s.y + 3
            local mid = p.x + max

            DL:AddLine(imgui.ImVec2(mid, Y), imgui.ImVec2(mid + (max * pool.h.alpha), Y), ToU32(set_alpha(pool.color, pool.h.alpha)), 3)
            DL:AddLine(imgui.ImVec2(mid, Y), imgui.ImVec2(mid - (max * pool.h.alpha), Y), ToU32(set_alpha(pool.color, pool.h.alpha)), 3)
        end

    imgui.EndGroup()
    return result
end

function im_input_with_hint(str_id, hint, value, size, path)
	if imgui.InputTextWithHint(str_id, hint, value, size) then
		configuration[path[1]][path[2]][path[3]] = str(value)
		if not need_update_configuration then need_update_configuration = os.clock() end
	end
end

function im_toggle_button(str_id, hint, path)
	local result
	if mimgui_addons.ToggleButton(str_id, new.bool(configuration[path[1]][path[2]][path[3]])) then
		configuration[path[1]][path[2]][path[3]] = not configuration[path[1]][path[2]][path[3]]
		result = true
		if not need_update_configuration then need_update_configuration = os.clock() end
	end
	if hint then imgui.SameLine() imgui.Text(hint) end
	return result, configuration[path[1]][path[2]][path[3]]
end

function im_toggle_button_A(str_id, hint, path)
	local result
	if mimgui_addons.ToggleButton(str_id, new.bool(configuration[path[1]][path[2]][path[3]][path[4]][path[5]])) then
		configuration[path[1]][path[2]][path[3]][path[4]][path[5]] = not configuration[path[1]][path[2]][path[3]][path[4]][path[5]]
		result = true
		if not need_update_configuration then need_update_configuration = os.clock() end
	end
	if hint then imgui.SameLine() imgui.Text(hint) end
	return result, configuration[path[1]][path[2]][path[3]][path[4]][path[5]]
end

function im_toggle_button_B(str_id, hint, path)
	local result
	if mimgui_addons.ToggleButton(str_id, new.bool(configuration[path[1]][path[2]][path[3]][path[4]])) then
		configuration[path[1]][path[2]][path[3]][path[4]] = not configuration[path[1]][path[2]][path[3]][path[4]]
		result = true
		if not need_update_configuration then need_update_configuration = os.clock() end
	end
	if hint then imgui.SameLine() imgui.Text(hint) end
	return result, configuration[path[1]][path[2]][path[3]][path[4]]
end

function im_circle_button(str_id, bool)
	if bool then
		imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonActive])
	else
    	imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.TextDisabled])
	end
    local button = imgui.Button("##" .. str_id, imgui.ImVec2(10, 10))
    imgui.PopStyleColor(1)
    return button
end

function im_slider_int(str_id, minimum, maximum, path)
	local value = new.int(configuration[path[1]][path[2]][path[3]])
	if imgui.SliderInt(str_id, value, minimum, maximum) then
		configuration[path[1]][path[2]][path[3]] = value[0]
		if not need_update_configuration then need_update_configuration = os.clock() end
	end
end

function im_slider_float(str_id, minimum, maximum, path)
	local value = new.float(configuration[path[1]][path[2]][path[3]])
	if imgui.SliderFloat(str_id, value, minimum, maximum) then
		configuration[path[1]][path[2]][path[3]] = value[0]
		if not need_update_configuration then need_update_configuration = os.clock() end
	end
end

function im_update_color()
	imgui.GetStyle().Colors[imgui.Col.ButtonActive] = imgui.ImVec4(im_float_color[0], im_float_color[1] + 0.1, im_float_color[2] + 0.1, 0.93)
	imgui.GetStyle().Colors[imgui.Col.ButtonHovered] = imgui.ImVec4(im_float_color[0], im_float_color[1] + 0.1, im_float_color[2] + 0.1, 0.89)
	imgui.GetStyle().Colors[imgui.Col.Button] = imgui.ImVec4(im_float_color[0], im_float_color[1], im_float_color[2], 0.85)

	imgui.GetStyle().Colors[imgui.Col.HeaderActive] = imgui.ImVec4(im_float_color[0], im_float_color[1] + 0.1, im_float_color[2] + 0.1, 0.93)
	imgui.GetStyle().Colors[imgui.Col.HeaderHovered] = imgui.ImVec4(im_float_color[0], im_float_color[1] + 0.1, im_float_color[2] + 0.1, 0.89)
	imgui.GetStyle().Colors[imgui.Col.Header] = imgui.ImVec4(im_float_color[0], im_float_color[1], im_float_color[2], 0.85)

	imgui.GetStyle().Colors[imgui.Col.SeparatorActive] = imgui.ImVec4(im_float_color[0], im_float_color[1] + 0.1, im_float_color[2] + 0.1, 0.93)
	imgui.GetStyle().Colors[imgui.Col.SeparatorHovered] = imgui.ImVec4(im_float_color[0], im_float_color[1] + 0.1, im_float_color[2] + 0.1, 0.89)
	imgui.GetStyle().Colors[imgui.Col.Separator] = imgui.ImVec4(im_float_color[0], im_float_color[1], im_float_color[2], 0.85)

	imgui.GetStyle().Colors[imgui.Col.SliderGrabActive] = imgui.ImVec4(im_float_color[0], im_float_color[1] + 0.1, im_float_color[2] + 0.1, 0.93)
	imgui.GetStyle().Colors[imgui.Col.SliderGrab] = imgui.ImVec4(im_float_color[0], im_float_color[1], im_float_color[2], 0.85)

	configuration["MAIN"]["customization"]["ButtonActive"] = {r = im_float_color[0], g = im_float_color[1] + 0.1, b = im_float_color[2] + 0.1, a = 0.93}
	configuration["MAIN"]["customization"]["ButtonHovered"] = {r = im_float_color[0], g = im_float_color[1] + 0.1, b = im_float_color[2] + 0.1, a = 0.89}
	configuration["MAIN"]["customization"]["Button"] = {r = im_float_color[0], g = im_float_color[1], b = im_float_color[2], a = 0.85}

	configuration["MAIN"]["customization"]["SeparatorActive"] = {r = im_float_color[0], g = im_float_color[1] + 0.1, b = im_float_color[2] + 0.1, a = 0.93}
	configuration["MAIN"]["customization"]["SeparatorHovered"] = {r = im_float_color[0], g = im_float_color[1] + 0.1, b = im_float_color[2] + 0.1, a = 0.89}
	configuration["MAIN"]["customization"]["Separator"] = {r = im_float_color[0], g = im_float_color[1], b = im_float_color[2], a = 0.85}

	configuration["MAIN"]["customization"]["HeaderActive"] = {r = im_float_color[0], g = im_float_color[1] + 0.1, b = im_float_color[2] + 0.1, a = 0.93}
	configuration["MAIN"]["customization"]["HeaderHovered"] = {r = im_float_color[0], g = im_float_color[1] + 0.1, b = im_float_color[2] + 0.1, a = 0.89}
	configuration["MAIN"]["customization"]["Header"] = {r = im_float_color[0], g = im_float_color[1], b = im_float_color[2], a = 0.85}

	configuration["MAIN"]["customization"]["SliderGrabActive"] = {r = im_float_color[0], g = im_float_color[1] + 0.1, b = im_float_color[2] + 0.1, a = 0.93}
	configuration["MAIN"]["customization"]["SliderGrab"] = {r = im_float_color[0], g = im_float_color[1], b = im_float_color[2], a = 0.85}

	local r, g, b = im_float_color[0] * 255, im_float_color[1] * 255, im_float_color[2] * 255
	local color = join_argb(255, r, g, b)
	configuration["MAIN"]["settings"]["script_color"] = string.format("{%s}", argb_to_hex(color))
	configuration["MAIN"]["settings"]["t_script_color"] = tonumber(bit.tohex(join_argb(255, b, g, r)), 16)
	configuration["MAIN"]["settings"]["timestamp_color"] = "0x" .. bit.tohex(join_argb(255, r, g, b), 6)

	if not need_update_configuration then need_update_configuration = os.clock() end
end

function string_pairs(text, size)
	local words = {}
	for word in string.gmatch(text, "[^%s]+") do table.insert(words, word) end

	local result = { "" }
	for index, value in ipairs(words) do
		local line = result[#result] .. value
		if string.len(line) < size then
			result[#result] = line .. " "
		else
			table.insert(result, value .. " ")
		end
	end

	local is_fix_without_space = false

	for index, value in ipairs(result) do
		if value == "" then
			is_fix_without_space = true
			result = {}
		elseif string.len(value) > size then
			is_fix_without_space = true
			result = {}
		end
	end

	if is_fix_without_space then
		local position = 0
		local step = math.ceil(string.len(text) / size)

		for index = 1, step do
			local finish_position = position + size
			if finish_position > string.len(text) then finish_position = string.len(text) end
			table.insert(result, string.sub(text, position, finish_position) .. " ")
			position = finish_position
		end
	end

	return result
end

function register_chat_command(command, callback, settings)
	if settings["status"] then
		sampRegisterChatCommand(command, _G[callback]) -- регистрируем команду
		if settings and settings["variations"] and #settings["variations"] > 0 then
			local ncommand = string.format("n%s", command)
			sampRegisterChatCommand(ncommand, function(parametrs)
				if string.match(parametrs, "(%S+)") then
					sampSendChat(string.format("/%s %s", command, parametrs))
				else chat_error(string.format("Введите необходимые параметры для /%s (параметры).", ncommand)) end
			end)
		end
	end
end

function register_custom_command(command, index, value)
	sampRegisterChatCommand(command, function(parametrs)
		lua_thread.create(function() command_handler("main", index, parametrs) end)
	end)

	if value["keys"] and value["keys"]["v"] then
		if not rkeys.isHotKeyDefined(value["keys"]["v"]) then
			rkeys.registerHotKey(value["keys"]["v"], true, function()
				if isKeyCheckAvailable() then
					lua_thread.create(function()
						command_handler("main", index, "")
					end)
				end
			end)
		end
	end
end

function patrol_direction()
    if sampIsLocalPlayerSpawned() then
        local angel = math.ceil(getCharHeading(PLAYER_PED))
        if angel then
            if (angel >= 0 and angel <= 30) or (angel <= 360 and angel >= 330) then
                return "Север", angel
            elseif (angel > 80 and angel < 100) then
                    return "Запад", angel
            elseif (angel > 260 and angel < 280) then
                    return "Восток", angel
            elseif (angel >= 170 and angel <= 190) then
                    return "Юг", angel
            elseif (angel >= 31 and angel <= 79) then
                    return "Северо-запад", angel
            elseif (angel >= 191 and angel <= 259) then
                    return "Юго-восток", angel
            elseif (angel >= 81 and angel <= 169) then
                    return "Юго-запад", angel
            elseif (angel >= 259 and angel <= 329) then
                    return "Северо-восток", angel
            else
                return "Неизвестно", angel
            end
        else
            return "Неизвестно", 0
        end
    else
        return "Неизвестно", 0
    end
end

function handler_low_action(index, parametrs)
	local sex = configuration["MAIN"]["settings"]["sex"] and "female" or "male"
	if configuration["CUSTOM"]["LOW_ACTION"][sex][index]["status"] then
		lua_thread.create(function() wait(10)
			local acting = configuration["CUSTOM"]["LOW_ACTION"][sex][index]["variations"]
			local acting = acting[math.random(1, #acting)]
			final_command_handler(acting, parametrs or {})
		end)
	end
end

function play_animation(library, animation, lock_A)
	if not hasAnimationLoaded(library) then requestAnimation(library) end
	taskPlayAnim(playerPed, animation, library, 9, lock_A, false, false, true, -1)
end

function clear_animation()
	local bs = raknetNewBitStream()
	raknetBitStreamWriteInt16(bs, tonumber(readMemory(sampGetPlayerPoolPtr() + 4, 1, false)))
	raknetEmulRpcReceiveBitStream(87, bs)
	raknetDeleteBitStream(bs)
end

function smart_ads(input)
	local half_weights = {"прод", "купл", "цена", "бюдже", "свобод", "догов"} -- половинные слова
			
	local input_pattern = string.nlower(string.gsub(u8:decode(str(input)), "%p+", " ")) -- отсекаем все знаки
	local t_input_pattern = {}

	for word in string.gmatch(input_pattern, "[^%s]+") do -- получаем все слова из исходного текста
		local weight = 1
		for index, value in ipairs(half_weights) do
			if string.match(word, value) then weight = 0.1 end -- снижаем массу слова
		end

		local len = string.len(word)
		if len > 2 then
			if len > 5 then word = string.sub(word, 1, len - 1) end
			table.insert(t_input_pattern, { word, weight }) 
		end
	end

	local repeats = {}
	local result = {}

	for index, value in ipairs(configuration["ADS"]) do
		local received_ad = string.nlower(string.gsub(u8:decode(configuration["ADS"][index]["received_ad"]), "%p+", " "))
		local corrected_ad = string.nlower(string.gsub(u8:decode(configuration["ADS"][index]["corrected_ad"]), "(%p+)?(%s+)", ""))

		if not repeats[received_ad] then
			repeats[received_ad] = true

			local r_matches = 0
			local c_matches = 0

			for key, word in ipairs(t_input_pattern) do
				if string.match(received_ad, word[1]) then
					r_matches = r_matches + word[2]
				end

				if string.match(corrected_ad, word[1]) then
					c_matches = c_matches + word[2]
				end
			end

			if r_matches > 0.5 or c_matches > 0.5 then
				local r_matches = 0
				local c_matches = 0
				local t_received_pattern = {}

				for word in string.gmatch(received_ad, "[^%s]+") do
					local weight = 1
					for index, value in ipairs(half_weights) do
						if string.match(word, value) then weight = 0.1 end -- снижаем массу слова
					end

					if string.len(word) > 2 then
						table.insert(t_received_pattern, { word, weight })
					end
				end

				for index_1, word_1 in ipairs(t_received_pattern) do
					for index_2, word_2 in ipairs(t_input_pattern) do
						if word_1[1] == word_2[1] then
							r_matches = r_matches + word_1[2] + 0.2
						elseif string.match(word_1[1], word_2[1]) then
							r_matches = r_matches + word_1[2]
						end
					end
				end

				local t_corrected_pattern = {}

				for word in string.gmatch(corrected_ad, "[^%s]+") do
					local weight = 1
					for index, value in ipairs(half_weights) do
						if string.match(word, value) then weight = 0.1 end -- снижаем массу слова
					end

					if string.len(word) > 2 then
						table.insert(t_corrected_pattern, { word, weight })
					end
				end

				for index_1, word_1 in ipairs(t_corrected_pattern) do
					for index_2, word_2 in ipairs(t_input_pattern) do
						if word_1[1] == word_2[1] then
							c_matches = c_matches + word_1[2] + 0.2
						elseif string.match(word_1[1], word_2[1]) then
							c_matches = c_matches + word_1[2]
						end
					end
				end

				local matches = r_matches + c_matches

				table.insert(result, {
					["matches"] = matches,
					["corrected"] = configuration["ADS"][index]["corrected_ad"],
					["received"] = configuration["ADS"][index]["received_ad"],
					["description"] = string.format(u8 "Отправил %s в %s", configuration["ADS"][index]["author"], os.date("%H:%M %d-%m-%Y", configuration["ADS"][index]["finish_of_verification"]))
				})
			end
		end
	end

	table.sort(result, function(a, b) return (a["matches"] > b["matches"]) end) 
	return result
end

function mimgui_window(index, bool)
	if t_mimgui_render[index] then
		t_mimgui_render[index]["switch"]()
	end
end

local t_words_ending = {
	["секунда"] = {
		[1] = "секунду", [2] = "секунды", [3] = "секунды", [4] = "секунды", [5] = "секунд", 
		[6] = "секунд", [7] = "секунд", [8] = "секунд", [9] = "секунд", [10] = "секунд",
		[11] = "секунд", [12] = "секунд", [13] = "секунд", [14] = "секунд", [15] = "секунд",
		[16] = "секунд", [17] = "секунд", [18] = "секунд", [19] = "секунд", [20] = "секунд",
	}
}

function get_words_ending(word, number)
	local number = tonumber(number)
	if not number then return end

	local string_number = string.format("%d", number)
	local len = string.len(string_number)
	local one_char = tonumber(string.sub(string_number, len, len))
	local two_char = tonumber(string.sub(string_number, len - 1, len))

	if t_words_ending[word][two_char] then
		return t_words_ending[word][two_char]
	elseif t_words_ending[word][one_char] then
		return t_words_ending[word][one_char]
	else
		return word
	end
end

function submenus_show(menu, caption, select_button, close_button, back_button)
    select_button, close_button, back_button = select_button or 'Select', close_button or 'Close', back_button or 'Back'
    prev_menus = {}
    function display(menu, id, caption)
        local string_list = {}
        for i, v in ipairs(menu) do
            table.insert(string_list, type(v.submenu) == 'table' and v.title or v.title)
        end
        sampShowDialog(id, caption, table.concat(string_list, '\n'), select_button, (#prev_menus > 0) and back_button or close_button, 5)
        repeat
            wait(0)
            local result, button, list = sampHasDialogRespond(id)
			local list = list + 1
            if result then
                if button == 1 and list ~= -1 then
                    local item = menu[list + 1]
                    if type(item.submenu) == 'table' then -- submenu
                        table.insert(prev_menus, {menu = menu, caption = caption})
                        if type(item.onclick) == 'function' then
                            item.onclick(menu, list + 1, item.submenu)
                        end
                        return display(item.submenu, id + 1, item.submenu.title and item.submenu.title or item.title)
                    elseif type(item.onclick) == 'function' then
                        local result = item.onclick(menu, list + 1)
                        if not result then return result end
                        return display(menu, id, caption)
                    end
                else -- if button == 0
                    if #prev_menus > 0 then
                        local prev_menu = prev_menus[#prev_menus]
                        prev_menus[#prev_menus] = nil
                        return display(prev_menu.menu, id - 1, prev_menu.caption)
                    end
					menu = nil
                    return false
                end
            end
        until result
    end
    return display(menu, 31337, caption or menu.title)
end
-- !function

-- event
function sampev.onServerMessage(color, text)
	if color == 13369599 then
		if string.match(text, "(.+) %| Отправил%s(%S+)%[(%d+)%] %(тел%. (%d+)%)") then -- mass media ad
			local ad, player_nickname, player_id, player_number = string.match(text, "(.+) %| Отправил%s(%S+)%[(%d+)%] %(тел%. (%d+)%)")

			if not configuration["DATABASE"]["player"][player_nickname] then configuration["DATABASE"]["player"][player_nickname] = {} end 
			configuration["DATABASE"]["player"][player_nickname]["telephone"] = player_number

			if not need_update_configuration then need_update_configuration = os.clock() end
			if configuration["MAIN"]["settings"]["ad_blocker"] then print(text) return false end
		end
	elseif color == 10027263 then
		if string.match(text, "  Объявление проверил сотрудник СМИ") then -- mass media editor ad
			if configuration["MAIN"]["settings"]["ad_blocker"] then print(text, "\n") return false end
		end
	elseif color == -65281 then
		if string.match(text, "SMS.[%s](.+)[%s].[%s]Отправитель.[%s](%S+)[%s].т.(%d+).") then -- sms message
			local ftext, player_name, player_number = string.match(text, "SMS.[%s](.+)[%s].[%s]Отправитель.[%s](%S+)[%s].т.(%d+).")

			if not configuration["DATABASE"]["player"][player_name] then configuration["DATABASE"]["player"][player_name] = {} end
			configuration["DATABASE"]["player"][player_name]["telephone"] = player_number

			last_sms_number = player_number
			if not need_update_configuration then need_update_configuration = os.clock() end
			if configuration["MAIN"]["blacklist"][player_name] then return false end
		elseif string.match(text, "SMS.[%s](.+)[%s].[%s]Получатель.[%s](%S+)[%s].т.(%d+).") then -- sms message
			local ftext, player_name, player_number = string.match(text, "SMS.[%s](.+)[%s].[%s]Получатель.[%s](%S+)[%s].т.(%d+).")

			if not configuration["DATABASE"]["player"][player_name] then configuration["DATABASE"]["player"][player_name] = {} end
			configuration["DATABASE"]["player"][player_name]["telephone"] = player_number

			if not need_update_configuration then need_update_configuration = os.clock() end
		end
	elseif color == 869033727 then
		if string.match(text, "%[R%] (.+) (%S+)%[(%d+)%]: (.+)") then -- departament radio
			local player_rang, player_nickname, player_id, text = string.match(text, "%[R%] (.+) (%S+)%[(%d+)%]: (.+)")
			if configuration["MAIN"]["settings"]["new_radio"] then
				if configuration["USERS"]["content"][player_nickname] then
					sampAddChatMessage(string.format("[R] %s %s%s{9ACD32}[%s]: %s", player_rang, configuration["USERS"]["content"][player_nickname]["color"], string.gsub(player_nickname, "_", " "), player_id, text), 0x9ACD32)
					return false
				else
					sampAddChatMessage(("[R] %s %s[%s]: %s"):format(player_rang, string.gsub(player_nickname, "_", " "), player_id, text), 0x9ACD32)
					return false
				end
			end
		end
	elseif color == 1721355519 then
		if string.match(text, "%[F%] (.+) (%S+)%[(%d+)%]: (.+)") then -- organization radio
			local player_rang, player_nickname, player_id, text = string.match(text, "%[F%] (.+) (%S+)%[(%d+)%]: (.+)")
			if configuration["MAIN"]["settings"]["new_radio"] then
				if configuration["USERS"]["content"][player_nickname] then
					sampAddChatMessage(string.format("[F] %s %s%s{20B2AA}[%s]: %s", player_rang, configuration["USERS"]["content"][player_nickname]["color"], string.gsub(player_nickname, "_", " "), player_id, text), 0x20B2AA)
					return false
				else
					sampAddChatMessage(("[F] %s %s[%s]: %s"):format(player_rang, string.gsub(player_nickname, "_", " "), player_id, text), 0x20B2AA)
					return false
				end
			end
		end
	elseif color == -577699841 then
		if string.match(text, "(.+) (%S+) изъял у (%S+) патроны .(%d+) шт..") then -- take bullets
			local officer_rang, officer_nickname, suspect_nickname, bullets = string.match(text, "(.+) (%S+) изъял у (%S+) патроны .(%d+) шт..")
			local result, player_id = sampGetPlayerIdByCharHandle(playerPed)
			if officer_nickname == sampGetPlayerName(player_id) then
				handler_low_action("bullets", { bullets })

				configuration["STATISTICS"]["police"]["bullets"] = configuration["STATISTICS"]["police"]["bullets"] + tonumber(bullets)
				if not need_update_configuration then need_update_configuration = os.clock() end
			end
		elseif string.match(text, "(.+) (%S+) изъял у (%S+) (%d+) г наркотиков") then -- take drugs
			local officer_rang, officer_nickname, suspect_nickname, drugs = string.match(text, "(.+) (%S+) изъял у (%S+) (%d+) г наркотиков")
			local result, player_id = sampGetPlayerIdByCharHandle(playerPed)
			if officer_nickname == sampGetPlayerName(player_id) then
				handler_low_action("drugs", { drugs })

				configuration["STATISTICS"]["police"]["drugs"] = configuration["STATISTICS"]["police"]["drugs"] + tonumber(drugs)
				if not need_update_configuration then need_update_configuration = os.clock() end
			end
		elseif string.match(text, "^(.+) (%S+) изъял у (%S+) (.+)$") then -- take weapon
			local officer_rang, officer_nickname, suspect_nickname, weapon = string.match(text, "^(.+) (%S+) изъял у (%S+) (.+)$")
			local result, player_id = sampGetPlayerIdByCharHandle(playerPed)
			if officer_nickname == sampGetPlayerName(player_id) then
				handler_low_action("weapons", { weapon })

				local index_weapon = string.gsub(weapon, " ", "_")
				configuration["STATISTICS"]["police"]["weapons_number"] = configuration["STATISTICS"]["police"]["weapons_number"] + 1
				if not configuration["STATISTICS"]["police"]["weapons"] then configuration["STATISTICS"]["police"]["weapons"] = {} end
				if not configuration["STATISTICS"]["police"]["weapons"][index_weapon] then
					configuration["STATISTICS"]["police"]["weapons"][index_weapon] = 1
				else
					configuration["STATISTICS"]["police"]["weapons"][index_weapon] = configuration["STATISTICS"]["police"]["weapons"][index_weapon] + 1
				end
				if not need_update_configuration then need_update_configuration = os.clock() end
			end
		elseif string.match(text, "^(.+) (%S+) произвёл обыск у (%S+)$") then -- search
			local officer_rang, officer_nickname, suspect_nickname = string.match(text, "^(.+) (%S+) произвёл обыск у (%S+)$")

			local result, player_id = sampGetPlayerIdByCharHandle(playerPed)
			if officer_nickname == sampGetPlayerName(player_id) then
				configuration["STATISTICS"]["police"]["search"] = configuration["STATISTICS"]["police"]["search"] + 1
				if not need_update_configuration then need_update_configuration = os.clock() end
			end
		elseif string.match(text, "^(.+) (%S+) надел на (%S+) наручники$") then -- cuff
			local officer_rang, officer_nickname, suspect_nickname = string.match(text, "^(.+) (%S+) надел на (%S+) наручники$")

			local result, player_id = sampGetPlayerIdByCharHandle(playerPed)
			if officer_nickname == sampGetPlayerName(player_id) then
				configuration["STATISTICS"]["police"]["cuff"] = configuration["STATISTICS"]["police"]["cuff"] + 1
				if not need_update_configuration then need_update_configuration = os.clock() end
			end
		elseif string.match(text, "^(.+) (%S+) снял с (%S+) наручники$") then -- uncuff
			local officer_rang, officer_nickname, suspect_nickname = string.match(text, "^(.+) (%S+) посадил (%S+) в машину$")
			local result, player_id = sampGetPlayerIdByCharHandle(playerPed)
			if officer_nickname == sampGetPlayerName(player_id) then
				configuration["STATISTICS"]["police"]["uncuff"] = configuration["STATISTICS"]["police"]["uncuff"] + 1
				if not need_update_configuration then need_update_configuration = os.clock() end
			end
		elseif string.match(text, "^(.+) (%S+) посадил (%S+) в машину$") then -- putpl
			local officer_rang, officer_nickname, suspect_nickname = string.match(text, "^(.+) (%S+) посадил (%S+) в машину$")
			local result, player_id = sampGetPlayerIdByCharHandle(playerPed)
			if officer_nickname == sampGetPlayerName(player_id) then
				if patrol_status["status"] then
					create_offer(1, function() command_r("cod 14") end)
					lua_thread.create(function() wait(10)
						chat("Если Вы желаете объвить о том, что доставляете подозреваемого в департамент, нажмите {HEX}Y{}.")
					end)
				end

				configuration["STATISTICS"]["police"]["putpl"] = configuration["STATISTICS"]["police"]["putpl"] + 1
				if not need_update_configuration then need_update_configuration = os.clock() end
			end
		elseif string.match(text, "Сейчас у Вас аптечек: {33cc33}(%d) шт.") then -- auto buy aidkit
			if configuration["MAIN"]["settings"]["auto_buy_mandh"] then
				local aid = tonumber(string.match(text, "Сейчас у Вас аптечек: {33cc33}(%d+) шт."))
				local aid = 5 - aid
				t_need_to_purchase["aid"] = aid
			end
		elseif string.match(text, "Сейчас у Вас масок: {33cc33}(%d) шт.") then -- auto buy mask
			if configuration["MAIN"]["settings"]["auto_buy_mandh"] then
				local mask = tonumber(string.match(text, "Сейчас у Вас масок: {33cc33}(%d+) шт."))
				local mask = 3 - mask
				t_need_to_purchase["mask"] = mask
			end
		end
	elseif color == 865730559 then
		if string.match(text, "Вы оглушили (%S+) на 15 секунд") then -- suspect taser
			local player_nickname = string.match(text, "Вы оглушили (%S+) на 15 секунд")
			local player_id = sampGetPlayerIdByNickname(player_nickname)

			if getCurrentCharWeapon(playerPed) == 3 then
				handler_low_action("baton", { player_id, player_nickname })

				configuration["STATISTICS"]["police"]["baton"] = configuration["STATISTICS"]["police"]["baton"] + 1
				if not need_update_configuration then need_update_configuration = os.clock() end
			else
				handler_low_action("taser", { player_id, player_nickname })

				configuration["STATISTICS"]["police"]["taser"] = configuration["STATISTICS"]["police"]["taser"] + 1
				if not need_update_configuration then need_update_configuration = os.clock() end
			end
		elseif string.match(text, "Вы использовали аптечку. Здоровье пополнено на 60 единиц") then -- use aidkit
			if configuration["MAIN"]["settings"]["aid_timer"] then
				local is_player_use_aidkit = false

				for index, value in ipairs(t_player_text) do
					if value and value["type"] == 1 then is_player_use_aidkit = true end
				end

				if not is_player_use_aidkit then
					configuration["STATISTICS"]["time_using_aid_kits"] = configuration["STATISTICS"]["time_using_aid_kits"] + 5.5
					if not need_update_configuration then need_update_configuration = os.clock() end
					create_player_text(1)
				end
			end

			handler_low_action("healme") -- low rp
		elseif string.match(text, "Вы объявили (%S+) в розыск%. Причина: (.+)%. Текущий уровень розыска (%d+)") then -- add suspect
			local suspect_nickname, reason, wanted = string.match(text, "Вы объявили (%S+) в розыск%. Причина: (.+)%. Текущий уровень розыска (%d+)")
			local suspect_id = sampGetPlayerIdByNickname(suspect_nickname)
			local result, officer_id = sampGetPlayerIdByCharHandle(playerPed)
			local officer_nickname = sampGetPlayerName(officer_id)

			if not configuration["DATABASE"]["player"][suspect_nickname] then configuration["DATABASE"]["player"][suspect_nickname] = {} end
			if not configuration["DATABASE"]["player"][suspect_nickname]["wanted_log"] then configuration["DATABASE"]["player"][suspect_nickname]["wanted_log"] = {} end

			table.insert(configuration["DATABASE"]["player"][suspect_nickname]["wanted_log"], {
				officer_rang = rang,
				officer_nickname = officer_nickname,
				suspect_nickname = suspect_nickname,
				wanted = tonumber(wanted),
				time = os.time(),
				ok = was_pause
			})

			if suspect_id and isPlayerConnected(suspect_id) then
				if t_last_suspect_parametrs then
					if #t_smart_suspects > 0 then
						for index, suspect in ipairs(t_smart_suspects) do
							if suspect["suspect"]["id"] == suspect_id then
								for key, value in ipairs(suspect["alleged_violations"]) do
									if value["reason"] == reason then
										table.remove(t_smart_suspects[index]["alleged_violations"], key)
										if #t_smart_suspects[index]["alleged_violations"] == 0 then table.remove(t_smart_suspects, index) end
									end
								end
							end
						end
					end
				end
			end

			configuration["STATISTICS"]["police"]["suspects"] = configuration["STATISTICS"]["police"]["suspects"] + 1

			if not need_update_configuration then need_update_configuration = os.clock() end
		elseif string.match(text, "Вы выписали (.+) штраф в размере (%d+).. Причина. (.+)") then -- ticket
			local nickname, money, reason = string.match(text, "Вы выписали (.+) штраф в размере (%d+).. Причина. (.+)")
			local player_id = sampGetPlayerIdByNickname(nickname)
			if isPlayerConnected(player_id) then
				preliminary_check_suspect(player_id, 5, true)
			end

			configuration["STATISTICS"]["police"]["tickets"] = configuration["STATISTICS"]["police"]["tickets"] + 1
			if not need_update_configuration then need_update_configuration = os.clock() end
		elseif string.match(text, "Вы загрузили {FFAA00}(%d+) ед%. груза{3399FF}, отправляйтесь к месту разгрузки") then -- tk
			local products = string.match(text, "Вы загрузили {FFAA00}(%d+) ед%. груза{3399FF}, отправляйтесь к месту разгрузки")
			product_delivery_status = 2
		elseif string.match(text, "Вы привезли {FFAA00}(%d+) ед%. груза {3399FF}и получили {00cc99}(%d+)%${3399FF}%. Комиссия компании {ff8080}(%d+)%$") then -- tk
			local products, revenue, commission = string.match(text, "Вы привезли {FFAA00}(%d+) ед%. груза {3399FF}и получили {00cc99}(%d+)%${3399FF}%. Комиссия компании {ff8080}(%d+)%$")
			product_delivery_status = 0
		end
	elseif color == -5242625 then
		if string.match(text, "^(.+)%[(%d+)%] был обнаружен в районе {33CCCC}(.+)$") then -- smart su
			local player_nickname, player_id, area = string.match(text, "^(.+)%[(%d+)%] был обнаружен в районе {33CCCC}(.+)$")
			preliminary_check_suspect(player_id, 4, true, true)

			configuration["STATISTICS"]["police"]["setmark"] = configuration["STATISTICS"]["police"]["setmark"] + 1
			if not need_update_configuration then need_update_configuration = os.clock() end
		end
	elseif color == -4652801 then
		if string.match(text, "(.+) (%S+)%[(%d+)%] объявил (%S+)%[(%d+)%] в розыск %[(%d+)%/6], причина: (.+)") then -- another add suspect
			local rang, officer_nickname, officer_id, suspect_nickname, suspect_id, wanted, reason = string.match(text, "(.+) (%S+)%[(%d+)%] объявил (%S+)%[(%d+)%] в розыск %[(%d+)%/6], причина: (.+)")
			if not configuration["DATABASE"]["player"][suspect_nickname] then configuration["DATABASE"]["player"][suspect_nickname] = {} end
			if not configuration["DATABASE"]["player"][suspect_nickname]["wanted_log"] then configuration["DATABASE"]["player"][suspect_nickname]["wanted_log"] = {} end

			table.insert(configuration["DATABASE"]["player"][suspect_nickname]["wanted_log"], {
				officer_rang = rang,
				officer_nickname = officer_nickname,
				suspect_nickname = suspect_nickname,
				wanted = tonumber(wanted),
				reason = u8(reason),
				time = os.time(),
				ok = was_pause
			})

			if not need_update_configuration then need_update_configuration = os.clock() end
		elseif string.match(text, "(.+) (%S+)%[(%d+)%] снял розыск у (%S+)%[(%d+)%]") then -- another delete suspect
			local rang, officer_nickname, officer_id, suspect_nickname, suspect_id = string.match(text, "(.+) (%S+)%[(%d+)%] снял розыск у (%S+)%[(%d+)%]")
			if not configuration["DATABASE"]["player"][suspect_nickname] then configuration["DATABASE"]["player"][suspect_nickname] = {} end
			if not configuration["DATABASE"]["player"][suspect_nickname]["wanted_log"] then configuration["DATABASE"]["player"][suspect_nickname]["wanted_log"] = {} end

			table.insert(configuration["DATABASE"]["player"][suspect_nickname]["wanted_log"], {
				officer_rang = rang,
				officer_nickname = officer_nickname,
				suspect_nickname = suspect_nickname,
				wanted = 0,
				time = os.time(),
				ok = was_pause
			})

			if not need_update_configuration then need_update_configuration = os.clock() end
		end
	elseif color == 1147587839 then
		if string.match(text, "Гос%. новости: (%S+)%[(%d+)%]: (.+)") then -- goverment news
			local nickname, player_id, t_text = string.match(text, "Гос%. новости: (%S+)%[(%d+)%]: (.+)")
			if #goverment_news > 0 then
				local max_index = #goverment_news
				if goverment_news[max_index]["nickname"] == nickname then
					if os.clock() - goverment_news[max_index]["clock"] < 4 then
						goverment_news[max_index]["clock"], goverment_news[max_index]["time"] = os.clock(), os.time()
						table.insert(goverment_news[max_index]["value"], t_text)
					else
						goverment_news[max_index + 1] = {nickname = nickname, value = {t_text}, clock = os.clock(), time = os.time(), ok = was_pause}
					end
				else
					goverment_news[max_index + 1] = {nickname = nickname, value = {t_text}, clock = os.clock(), time = os.time(), ok = was_pause}
				end
			else
				goverment_news[1] = {nickname = nickname, value = {t_text}, clock = os.clock(), time = os.time(), ok = was_pause}
			end
		end
	elseif color == 1724645631 then
		if string.match(text, "Исходящий звонок . Номер. (%d+) {FFCD00}. Ожидание ответа от (.+)...") then -- outcoming call
			local player_number, player_name = string.match(text, "Исходящий звонок . Номер. (%d+) {FFCD00}. Ожидание ответа от (.+)...")

			if not configuration["DATABASE"]["player"][player_name] then configuration["DATABASE"]["player"][player_name] = {} end
			configuration["DATABASE"]["player"][player_name]["telephone"] = player_number

			if not need_update_configuration then need_update_configuration = os.clock() end
		elseif string.match(text, "Вы выбрали заказ. Отправляйтесь к месту загрузки") then -- tk
			product_delivery_status = 1
		elseif string.match(text, "(.+) принимает Ваше предложение") then -- accept
			if invite_player_id then
				if tonumber(invite_rang) > 1 then
					lua_thread.create(function()
						for i = 2, tonumber(invite_rang) do
							sampSendChat(string.format("/rang %s +", invite_player_id))
							wait(900)
						end invite_player_id, invite_rang = nil, nil
					end)
				end
			end
		elseif string.match(text, "Вы выполнили (%S+) процедуру {80aaff}(%S+){ffcc66} %- (%d+)%/5") then -- procedure
			local nickname, procedure, step = string.match(text, "Вы выполнили (%S+) процедуру {80aaff}(%S+){ffcc66} %- (%d+)%/5")
			if tonumber(step) ~= 5 then
				if not procedures_performed then procedures_performed = {} end
				table.insert(procedures_performed, { ["nickname"] = nickname, ["procedure"] = string.nlower(procedure), ["step"] = tonumber(step), ["time"] = os.time(), ["is"] = true })
				create_assistant_thread("procedures_performed")

				lua_thread.create(function() wait(1)
					chat(string.format("Был запущен таймер, который уведомит Вас о возможности продолжить процедуру."))
				end)
			end
		elseif string.match(text, "(%S+) выполнил Вам процедуру {80aaff}(%S+){ffcc66} %- (%d)%/5") then 
			local nickname, procedure, step = string.match(text, "(%S+) выполнил Вам процедуру {80aaff}(%S+){ffcc66} %- (%d)%/5")
			if tonumber(step) ~= 5 then
				if not procedures_performed then procedures_performed = {} end
				table.insert(procedures_performed, { ["nickname"] = nickname, ["procedure"] = string.nlower(procedure), ["step"] = tonumber(step), ["time"] = os.time() })
				create_assistant_thread("procedures_performed")

				lua_thread.create(function() wait(1)
					chat(string.format("Был запущен таймер, который уведомит Вас о возможности продолжить процедуру."))
				end)
			end
		end
	elseif color == 865730559 then
		if string.match(text, "Входящий звонок . Номер. (%d+) {FFCD00}. Вызывает (.+)") then -- incoming call
			local player_number, player_name = string.match(text, "Входящий звонок . Номер. (%d+) {FFCD00}. Вызывает (.+)")

			if not configuration["DATABASE"]["player"][player_name] then configuration["DATABASE"]["player"][player_name] = {} end
			configuration["DATABASE"]["player"][player_name]["telephone"] = player_number

			if not need_update_configuration then need_update_configuration = os.clock() end
			if configuration["MAIN"]["blacklist"][player_name] then return false end
		end
	elseif color == 1802202111 then
		if string.match(text, "Не флудите") then -- no flood :c
			if time_take_ads then
				time_take_ads = os.clock() + 2.5
			elseif fast_reconnect then
				return false
			end
		end
	elseif color == -825307393 then
		if string.match(text, "Сейчас у игрока (%d) уровень розыска. Вы можете его увеличить на (%d)") then -- su su su
			if t_last_suspect_parametrs then
				local lstars, nstars = string.match(text, "Сейчас у игрока (%d) уровень розыска. Вы можете его увеличить на (%d)")
				local suspect_stars = tonumber(nstars) < tonumber(t_last_suspect_parametrs[2]) and nstars or t_last_suspect_parametrs[2]
				lua_thread.create(function()
					wait(250)
					sampSendChat(string.format("/su %s %s %s", t_last_suspect_parametrs[1], suspect_stars, t_last_suspect_parametrs[3]))
					t_last_suspect_parametrs = false
				end)
			end
		elseif string.match(text, "У этого игрока сейчас максимальный уровень розыска") then -- no su
			if t_last_suspect_parametrs then t_last_suspect_parametrs = false end
		elseif string.match(text, "Нет новых объявлений") then
			if time_take_ads then return false end
		elseif string.match(text, "Такого игрока нет") then
			if fast_reconnect then
				return false
			end
		elseif string.match(text, "Вам необходимо перезайти в игру. Введите {ff751a}/q {CECECE}для выхода") then
			if fast_reconnect then
				lua_thread.create(function()
					wait(1) -- anticrash
					reconnect(0)
					fast_reconnect = false
				end)
			end
		end
	elseif color == 13434879 then
		if string.match(text, "^(%S+) обратился в полицию%. {.+}..to (%d+). для принятия вызова$") then -- call 911
			local player_nickname, player_id = string.match(text, "^(%S+) обратился в полицию%. {.+}..to (%d+). для принятия вызова$")
			t_accept_police_call = { ["nickname"] = player_nickname, ["id"] = player_id }
		end
	elseif color == 1724671743 then
		if string.match(text, "Объявление отредактировано и поставлено в очередь на публикацию") then
			create_player_text(0, 4.5, "{C22222}+ {e6e6fa}ОБЪЯВЛЕНИЕ ОТРЕДАКТИРОВАНО")
			configuration["STATISTICS"]["massmedia"]["ads"] = configuration["STATISTICS"]["massmedia"]["ads"] + 1
		end
	elseif color == -6732289 then -- ans
		if string.match(text, "Администратор (%S+)") then
			local admin_nickname = string.match(text, "Администратор (%S+)")
			if not configuration["DATABASE"]["player"][admin_nickname] then configuration["DATABASE"]["player"][admin_nickname] = {} end
			configuration["DATABASE"]["player"][admin_nickname]["admin"] = true
			if not need_update_configuration then need_update_configuration = os.clock() end
		end
	elseif color == -11521793 then -- наказания от администрации
		if string.match(text, "Администратор (%S+)") then
			local admin_nickname = string.match(text, "Администратор (%S+)")
			if not configuration["DATABASE"]["player"][admin_nickname] then configuration["DATABASE"]["player"][admin_nickname] = {} end
			configuration["DATABASE"]["player"][admin_nickname]["admin"] = true
			if not need_update_configuration then need_update_configuration = os.clock() end
		end
	elseif color == -3342081 then
		if string.match(text, "Администратор (%S+)") then
			local admin_nickname = string.match(text, "Администратор (%S+)")
			if not configuration["DATABASE"]["player"][admin_nickname] then configuration["DATABASE"]["player"][admin_nickname] = {} end
			configuration["DATABASE"]["player"][admin_nickname]["admin"] = true
			if not need_update_configuration then need_update_configuration = os.clock() end
		end
	end

	if configuration["MAIN"]["settings"]["id_postfix_after_nickname"] then
		if string.match(text, "(%a+)_(%a+)") then
			local highlited_colors = {[-4652801] = true, [13434879] = true, [1721355519] = true, [869033727] = true }

			local players_id = {}
			for player_id = 0, 1000 do
				if isPlayerConnected(player_id) then players_id[sampGetPlayerNickname(player_id)] = player_id end
			end

			local nicknames = {}
			for nickname in string.gmatch(text, "(%a+_%a+)") do nicknames[nickname] = true end

			if highlited_colors[color] then
				local string_contains_color = string.match(text, "{.+}")
				local r, g, b = explode_argb(color)
				local color = bit.tohex(join_argb(255, r, g, b), 6)
				local timestamp_color = string.format("0x%s", color)

				for nickname in pairs(nicknames) do
					if players_id[nickname] then
						if configuration["USERS"]["content"][nickname] then
							local nickname_with_id = string.format("%s%s{%s}[%s]", configuration["USERS"]["content"][nickname]["color"], string.gsub(nickname, "_", " "), bit.tohex(join_argb(255, r, g, b), 6), players_id[nickname])
							text = string.gsub(string.gsub(text, "%[" .. players_id[nickname] .. "%]", ""), nickname, nickname_with_id)
						else
							local nickname_with_id = string.format("%s[%s]", string.gsub(nickname, "_", " "), players_id[nickname])
							text = string.gsub(string.gsub(text, "%[" .. players_id[nickname] .. "%]", ""), nickname, nickname_with_id)
						end
					end
				end

				sampAddChatMessage(text, timestamp_color)
				return false
			else
				for nickname in pairs(nicknames) do
					if players_id[nickname] then
						local nickname_with_id = string.format("%s[%s]", string.gsub(nickname, "_", " "), players_id[nickname])
						text = string.gsub(string.gsub(text, "%[" .. players_id[nickname] .. "%]", ""), nickname, nickname_with_id)
					end
				end return {color, text}
			end
		end
	end
end

function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
	if dialogId == 9 then
		if string.match(title, "Дом занят") then
			if string.match(text, "Владелец:[\t]+{33CCFF}(%S+)\n\n{FFFFFF}Тип:[\t]+(.+)\nНомер[%s]дома:[\t]+(%d+)\nВместимость:[\t]+(%d+)[%s]чел.\nСтоимость:[\t]+(%d+)%$\nЕжедневная[%s]квартплата:[\t]+от[%s](%d+)%$") then
				local owner, house, number, capacity, price, rent =
				string.match(text, "Владелец:[\t]+{33CCFF}(%S+)\n\n{FFFFFF}Тип:[\t]+(.+)\nНомер[%s]дома:[\t]+(%d+)\nВместимость:[\t]+(%d+)[%s]чел.\nСтоимость:[\t]+(%d+)%$\nЕжедневная[%s]квартплата:[\t]+от[%s](%d+)%$")

				local x, y, z = getCharCoordinates(playerPed)
				local position = {x = x, y = y, z = z}

				local found = false
				for k, v in pairs(configuration["DATABASE"]["house"]) do if v.id == tonumber(number) then found = k end end
				if found then
					configuration["DATABASE"]["house"][found] = {id = tonumber(number), owner = owner, house = u8(house), capacity = tonumber(capacity), price = tonumber(price), rent = tonumber(rent), position = position, time = os.time()}
				else
					table.insert(configuration["DATABASE"]["house"], {id = tonumber(number), owner = owner, house = u8(house), capacity = tonumber(capacity), price = tonumber(price), rent = tonumber(rent), position = position, time = os.time()})
				end

				if not need_update_configuration then need_update_configuration = os.clock() end
			end
		end
	elseif dialogId == 10 then
		if string.match(title, "Дом на аукционе") or string.match(title, "Дом свободен") then
			if string.match(text, "Тип:[\t]+(.+)\nНомер[%s]дома:[\t]+(%d+)\n\nВместимость:[\t]+(%d+)[%s]чел.\nСтоимость:[\t]+(%d+)%$\nЕжедневная[%s]квартплата:[\t]+от[%s](%d+)%$") then
				local house, number, capacity, price, rent =
				string.match(text, "Тип:[\t]+(.+)\nНомер[%s]дома:[\t]+(%d+)\n\nВместимость:[\t]+(%d+)[%s]чел.\nСтоимость:[\t]+(%d+)%$\nЕжедневная[%s]квартплата:[\t]+от[%s](%d+)%$")

				local x, y, z = getCharCoordinates(playerPed)
				local position = {x = x, y = y, z = z}

				local found = false
				for k, v in pairs(configuration["DATABASE"]["house"]) do if v["id"] == tonumber(number) then found = k end end
				if found then
					configuration["DATABASE"]["house"][found] = {id = tonumber(number), house = u8(house), capacity = tonumber(capacity), price = tonumber(price), rent = tonumber(rent), position = position, time = os.time()}
				else
					table.insert(configuration["DATABASE"]["house"], {id = tonumber(number), house = u8(house), capacity = tonumber(capacity), price = tonumber(price), rent = tonumber(rent), position = position, time = os.time()})
				end

				if not need_update_configuration then need_update_configuration = os.clock() end
			end
		end
	elseif dialogId == 27 then
		if report_text then
			if string.match(title, "Меню игрока") then
				if string.match(text, "(%d+)%. Связь с администрацией") then
					local index = tonumber(string.match(text, "(%d+)%. Связь с администрацией"))
					sampSendDialogResponse(dialogId, 1, index - 1, -1)
					return false
				else
					report_text = nil
					chat("Произошла ошибка при попытке отправить сообщение администрации.")
					return false
				end
			end
		end
	elseif dialogId == 63 then
		if ti_improved_dialogues[2]["status"]() then
			if string.match(title, "В подразделении") or string.match(title, "В организации") then
				local output = "{e6e6fa}Имя\t{e6e6fa}Ранг и должность\t{e6e6fa}Телефон\t{e6e6fa}Дополнительно"

				for line in string.gmatch(text, "[^\n]+") do
					if string.match(line, "(%d+)%. (%S+)%[(%d+)%]\t(%d+) ранг. (.+)\t(%d+)\t(.+)") then
						local id, nickname, player_id, rang_number, rang_name, number, status = string.match(line, "(%d+)%. (%S+)%[(%d+)%]\t(%d+) ранг%. (.+)\t(%d+)\t(.+)")
						output = string.format("%s\n%s. %s[%s]{%s} **\t%s ранг. %s\t%s\t{ff5c33}%s", output, id, nickname, player_id, sampGetColorByPlayerId(player_id), rang_number, rang_name, number, status)
					elseif string.match(line, "(%d+)%. (%S+)%[(%d+)%]\t(%d+) ранг. (.+)\t(%d+)\t") then
						local id, nickname, player_id, rang_number, rang_name, number = string.match(line, "(%d+)%. (%S+)%[(%d+)%]\t(%d+) ранг%. (.+)\t(%d+)\t")
						output = string.format("%s\n%s. %s[%s]{%s} **\t%s ранг. %s\t%s\t{00cc99}Онлайн", output, id, nickname, player_id, sampGetColorByPlayerId(player_id), rang_number, rang_name, number)
					end
				end

				return {dialogId, style, title, button1, button2, output}
			end
		end
	elseif dialogId == 64 then
		if ti_improved_dialogues[2]["status"]() then
			if string.find(title, "{FFCD00}Информация о сотруднике") then
				local hours_today, minutes_today = string.match(text, "Время в игре сегодня: {aa80ff}(%d+) ч (%d+) мин")
				local afk_hours_today, afk_minutes_today = string.match(text, "AFK сегодня: {FF7000}(%d+) ч (%d+) мин")
				local hours_yesterday, minutes_yesterday = string.match(text, "Время в игре вчера: {aa80ff}(%d+) ч (%d+) мин")
				local afk_hours_yesterday, afk_minutes_yesterday = string.match(text, "AFK вчера: {FF7000}(%d+) ч (%d+) мин")

				local clean_online_today = (hours_today * 60 + minutes_today) - (afk_hours_today * 60 + afk_minutes_today)
				local clean_online_yesterday = (hours_yesterday * 60 + minutes_yesterday) - (afk_hours_yesterday * 60 + afk_minutes_yesterday)

				local text = string.format("%s\n{ffffff}Чистый онлайн: {6495ED}%d ч %d мин\n{ffffff}Чистый онлайн вчера: {6495ED}%d ч %d мин",
				text, math.floor(clean_online_today / 60), math.fmod(clean_online_today, 60), math.floor(clean_online_yesterday / 60), math.fmod(clean_online_yesterday, 60))
				return {dialogId, style, title, button1, button2, text}
			end
		end
	elseif dialogId == 80 then
		if report_text then
			if string.find(title,"Связь с администрацией") then
				sampSendDialogResponse(dialogId, 1, 0, report_text)
				report_text = nil
				return false
			end
		end
	elseif dialogId == 88 then
		if string.match(title, "Код с приложения") then
			local result, player_id = sampGetPlayerIdByCharHandle(playerPed)
			if result then
				local nickname = sampGetPlayerName(player_id)
				local nickname = string.gsub(nickname, "%[.+%]", "")
				local ip, port = sampGetCurrentServerAddress()
				local ip_adress = string.format("%s:%s", ip, port)
				if configuration["MANAGER"][ip_adress] and configuration["MANAGER"][ip_adress][nickname] then
					local seckey = configuration["MANAGER"][ip_adress][nickname]["gauth"]
					if seckey then
						local g = gauth.gencode(seckey, math.floor(os.time() / 30))
						sampSendDialogResponse(dialogId, 1, 1, g)
						return false
					end
				end
			end
		end
	elseif dialogId == 175 then
		if string.match(title, "Тюрьма") or string.match(title, "ФБР") or string.match(title, "Управление полиции") then
			if configuration["MAIN"]["settings"]["obtaining_weapons"] then
				local max_index = 0
				for value in string.gmatch(text, "[^\n]+") do max_index = max_index + 1 end

				for index = 1, max_index do
					if ti_obtaining_weapons[index] and ti_obtaining_weapons[index]["status"]() then
						sampSendDialogResponse(dialogId, 1, index - 1, -1)
					end
				end return false
			end
		end
	elseif dialogId == 176 then
		if ti_improved_dialogues[4]["status"]() then
			if string.match(title, "Точное время") then
				local hours_today, minutes_today = string.match(text, "Время в игре сегодня:\t+{ffcc00}(%d+) ч (%d+) мин")
				local afk_hours_today, afk_minutes_today = string.match(text, "AFK за сегодня:\t+{FF7000}(%d+) ч (%d+) мин")
				local hours_yesterday, minutes_yesterday = string.match(text, "Время в игре вчера:\t+{ffcc00}(%d+) ч (%d+) мин")
				local afk_hours_yesterday, afk_minutes_yesterday = string.match(text, "AFK за вчера:\t+{FF7000}(%d+) ч (%d+) мин")

				local clean_online_today = (hours_today * 60 + minutes_today) - (afk_hours_today * 60 + afk_minutes_today)
				local clean_online_yesterday = (hours_yesterday * 60 + minutes_yesterday) - (afk_hours_yesterday * 60 + afk_minutes_yesterday)

				local text = string.format("%s\n{ffffff}Чистый онлайн:\t\t{6495ED}%d ч %d мин\n{ffffff}Чистый онлайн вчера:\t{6495ED}%d ч %d мин",
				text, math.floor(clean_online_today / 60), math.fmod(clean_online_today, 60), math.floor(clean_online_yesterday / 60), math.fmod(clean_online_yesterday, 60))
				return {dialogId, style, title, button1, button2, text}
			end
		end
	elseif dialogId == 224 then
		if ti_improved_dialogues[7]["status"]() then
			if string.match(title, "{00CC33}Публикация объявления") then
				if string.match(text, "Отправитель:[\t]+(%S+)\nТекст:[\t]+{FFCC15}(.+)\n\n{FFFFFF}") then
					local author, ad = string.match(text, "Отправитель:[\t]+(%S+)\nТекст:[\t]+{FFCC15}(.+)\n\n{FFFFFF}")
					local is_found = false
					local is_rp_nickname = string.match(author, "%L%l+_%L%l+")

					imgui_editor_ads = new.char[256]()

					for index = table.maxn(configuration["ADS"]), 1, -1 do
						local base_ad = u8:decode(configuration["ADS"][index]["received_ad"])
						if string.gsub(base_ad, "%s+", "") == string.gsub(ad, "%s+", "") then
							chat(string.format("Найдено схожее объявление #{HEX}%s{} от %s.", index, os.date("%H:%M %d-%m-%Y", configuration["ADS"][index]["finish_of_verification"])))
							if time_take_ads and is_rp_nickname and configuration["ADS"][index]["button"] == 1 then
								local fix_ad = string.gsub(u8:decode(configuration["ADS"][index]["corrected_ad"]), "TV |", "WMA |")
								sampSendDialogResponse(dialogId, configuration["ADS"][index]["button"], 1, fix_ad)
								return false
							else
								imgui_editor_ads = new.char[256](configuration["ADS"][index]["corrected_ad"])
								break
							end
						end
					end

					imgui_quick_editor_ads = new.char[256](u8(ad))
					t_quick_editor_update = os.clock()

					t_quick_ads = {
						["dialog_id"] = dialogId,
						["author"] = author,
						["ad"] = ad,
						["time"] = os.time(),
						["corrected_ad"] = is_found,
						["rp_nickname"] = is_rp_nickname
					}

					mimgui_window("editor_ads", true)
					return false
				end
			end
		end
	elseif dialogId == 317 then
		if ti_improved_dialogues[3]["status"]() then
			if string.match(title, "Список разыскиваемых") then
				local list_for_sort, max_index, line_index = {}, 0, 0

				for line in string.gmatch(text, "[^\n]+") do
					line_index = line_index + 1
					if string.match(line, "(%S+)[%s].id[%s](%d+).	(%d+)	 (%d+)") then
						local nickname, player_id, stars, distance = string.match(line, "(%S+)[%s].id[%s](%d+).	(%d+)	 (%d+)")
						max_index = max_index + 1
						list_for_sort[max_index] = {index = line_index, player_id = player_id, distance = tonumber(distance), line = string.format("{%s}%s{e6e6fa} (id %d)\t%d\t{00cc99}%s м", sampGetColorByPlayerId(player_id), nickname, player_id, stars, distance)}
					elseif string.match(line, "(%S+)[%s].id[%s](%d+).	(%d+)	Недоступно") then
						local nickname, player_id, stars = string.match(line, "(%S+)[%s].id[%s](%d+).	(%d+)	Недоступно")
						max_index = max_index + 1
						list_for_sort[max_index] = {index = line_index, player_id = player_id, distance = 7777, line = string.format("{%s}%s{e6e6fa} (id %d)\t%d\t{ff5c33}Недоступно", sampGetColorByPlayerId(player_id), nickname, player_id, stars)}
					end
				end

				table.sort(list_for_sort, function(a, b) return a["distance"] < b["distance"] end)
				local output = "{e6e6fa}Имя\t{e6e6fa}Уровень розыска\t{e6e6fa}Дистанция"
				for k, v in pairs(list_for_sort) do output = string.format("%s\n%s", output, v["line"]) end

				global_wanted = {dialogId = dialogId, output = list_for_sort}

				return {dialogId, style, title, button1, button2, output}
			end
		end -- wanted
	elseif dialogId == 373 then
		if configuration["MAIN"]["settings"]["auto_buy_mandh"] then
			if string.match(title, "Покупка аптечек") then
				if t_need_to_purchase["aid"] > 0 then
					sampSendDialogResponse(dialogId, 1, t_need_to_purchase["aid"] - 1, -1)
					sampSendDialogResponse(dialogId, 0, -1, -1)
					sampSendChat("/buy")
					return false
				else
					-- sampSendDialogResponse(dialogId, 0, -1, -1)
					sampSendChat("/buy")
					return false
				end
			end
		end
	elseif dialogId == 374 then
		if configuration["MAIN"]["settings"]["auto_buy_mandh"] then
			if string.find(title, "Покупка масок") then
				if t_need_to_purchase["mask"] > 0 then
					sampSendDialogResponse(dialogId, 1, t_need_to_purchase["mask"] - 1, -1)
					sampSendDialogResponse(dialogId, 0, -1, -1)
					sampSendChat("/buy")
					return false
				else
					-- sampSendDialogResponse(dialogId, 0, -1, -1)
					sampSendChat("/buy")
					return false
				end
			end
		end
	elseif dialogId == 414 then 
		if string.match(title, "Детализация по отчёту за сегодня") then 
			local index = 1
			for line in string.gmatch(text, "[^\n]+") do 
				text = string.gsub(text, line, string.format("{ffffff}№%s\t%s", index, line))
				index = index + 1
			end
			return { dialogId, style, title, button1, button2, text }
		end
	elseif dialogId == 424 then
		if ti_improved_dialogues[1]["status"]() then
			if string.match(title, "Лидеры") then
				local output = "{e6e6fa}Имя\t{e6e6fa}Организация\t{e6e6fa}Должность\t{e6e6fa}Статус\n"
				local total, online = 0, 0

				for line in string.gmatch(text, "[^\n]+") do
					if total ~= 0 then
						local nickname, position, fraction, status = string.match(line, "(.+)\t(.+)\t(.+)\t(.+)")
						local player_id = sampGetPlayerIdByNickname(nickname)
						if not player_id then output = string.format("%s{696969}%s\t{696969}%s\t{696969}%s\t{ff5c33}Оффлайн\n", output, nickname, position, fraction)
						else
							online = online + 1
							output = string.format(string.format("%s{%s}%s\t%s\t%s\t{00cc99}Онлайн\n", output, sampGetColorByPlayerId(player_id), nickname, position, fraction))
						end
					end total = total + 1
				end

				local caption = string.format("{e6e6fa}Всего лидеров {FFCD00}%d чел. {00CC66}(онлайн %d)", total, online)
				return {dialogId, style, caption, button1, button2, output}
			end
		end
	elseif dialogId == 480 then
		if drop_all then
			if string.match(title, "Какое оружие выбросить?") then
				sampSendDialogResponse(dialogId, 1, 0, -1)
				drop_all = false
				return false
			end
		end
	elseif dialogId == 487 then
		if string.match(title, "Паспорт") then
			local match = "{%S+}Имя:\t+{%S+}(%S+)\n{%S+}Проживание в стране %(лет%):\t+{%S+}(%S+)\n{%S+}Пол:\t+(%S+)\nСемейное положение:\t+(.+)\nПроживание:\t+{%S+}(.+)\n{%S+}Работа: \t+(.+)\nОрганизация:\t+(.+)\nПодразделение:\t+(.+)\nТелефон:\t+{%S+}(%S+)\n{%S+}Уровень розыска:\t+{%S+}(%S+)\n{%S+}Законопослушность:\t+{%S+}(%S+)"

			if string.match(text, match) then
				local nickname, residence_in_country, male, marital_status, accommodation, job, organization, department, telephone, wanted, law_abidingness = string.match(text, match)

				if not configuration["DATABASE"]["player"][nickname] then configuration["DATABASE"]["player"][nickname] = {} end

				configuration["DATABASE"]["player"][nickname]["residence_in_country"] = tonumber(residence_in_country)
				configuration["DATABASE"]["player"][nickname]["male"] = u8(male)
				configuration["DATABASE"]["player"][nickname]["marital_status"] = u8(marital_status)
				configuration["DATABASE"]["player"][nickname]["accommodation"] = u8(accommodation)
				configuration["DATABASE"]["player"][nickname]["job"] = u8(job)
				configuration["DATABASE"]["player"][nickname]["organization"] = u8(organization)
				configuration["DATABASE"]["player"][nickname]["department"] = u8(department)
				configuration["DATABASE"]["player"][nickname]["telephone"] = u8(telephone)
				configuration["DATABASE"]["player"][nickname]["wanted"] = tonumber(wanted)
				configuration["DATABASE"]["player"][nickname]["law_abidingness"] = tonumber(law_abidingness)
				configuration["DATABASE"]["player"][nickname]["time"] = os.time()

				if not need_update_configuration then need_update_configuration = os.clock() end

				if passport_check then
					if configuration["MAIN"]["settings"]["passport_check"] then
						lua_thread.create(function()
							if not configuration["MAIN"]["information"]["sex"] then
								sampSendChat("/me внимательно изучил паспортные данные и передал информацию диспетчеру.")
							else
								sampSendChat("/me внимательно изучила паспортные данные и передала информацию диспетчеру.")
							end

							if tonumber(wanted) > 0 then
								wait(1500); sampSendChat("/todo Получив информацию от диспетчера*Вы находитесь в федеральном розыске.")
								wait(1000); sampSendChat("Вам необходимо проехать со мной в ближайщий полицейский департамент.")
							else
								wait(1500); sampSendChat("/todo Получив информацию от диспетчера и вернув паспорт*С документами всё хорошо.")
							end
						end)
					end
					sampSendDialogResponse(dialogId, 1, 0, 0)
					passport_check = false
					return false
				end
			end
		end
	elseif dialogId == 3079 then
		if ti_improved_dialogues[6]["status"]() then
			if string.match(title, "Список заказов") then
				local line_index = 0
				list_of_orders["value"] = {}

				for lines in string.gmatch(text, "[^\n]+") do
					if string.match(lines, "(.+)[%s]%-[%s](.+),[%s](%d+)%$[\t]+(%d+)/(%d+)[\t]+(%d+)") then
						local point_start, point_finish, price_per_unit, quantity_product, total_product, drivers = string.match(lines, "(.+)[%s]%-[%s](.+),[%s](%d+)%$[\t]+(%d+)/(%d+)[\t]+(%d+)")
						table.insert(list_of_orders["value"], {
							index = line_index,
							point_start = string.gsub(point_start, "{.+}", ""),
							point_finish = string.gsub(point_finish, "{.+}", ""),
							price_per_unit = tonumber(price_per_unit),
							total_price = (tonumber(total_product) - tonumber(quantity_product)) * tonumber(price_per_unit),
							quantity_product = tonumber(quantity_product),
							total_product = tonumber(total_product),
							delta_product = tonumber(total_product) - tonumber(quantity_product),
							drivers = tonumber(drivers)
						})
					end line_index = line_index + 1
				end

				table.sort(list_of_orders["value"], function(a, b) return a["total_price"] > b["total_price"] end)

				local text = "Откуда\tКуда\tСтоимость разницы товаров\tВодителей на маршруте"
				for index, value in ipairs(list_of_orders["value"]) do
					local dcolor = value["drivers"] > 0 and "{999999}" or "{FFFFFF}"
					local point_start, point_finish = value["point_start"], value["point_finish"]
					local distance_tsp = t_points_completed_orders[point_start] and math.ceil(getDistanceBetweenCoords3d(x, y, z, t_points_completed_orders[point_start]["x"], t_points_completed_orders[point_start]["y"], t_points_completed_orders[point_start]["z"]))
					local distance_tfp = t_points_completed_orders[point_finish] and math.ceil(getDistanceBetweenCoords3d(x, y, z, t_points_completed_orders[point_finish]["x"], t_points_completed_orders[point_finish]["y"], t_points_completed_orders[point_finish]["z"]))
					text = string.format("%s\n%s%s ({00CC66}%s%s м)\t%s%s ({00CC66}%s%s м)\t{ffcc00}%s$%s за {6495ED}%s%s единиц\t%s%s",
						text, dcolor, value["point_start"], distance_tsp, dcolor, dcolor, value["point_finish"], distance_tfp, dcolor, value["total_price"], dcolor, value["delta_product"], dcolor, dcolor, value["drivers"])
				end

				list_of_orders["time"] = os.time()

				return {dialogId, style, title, button1, button2, text}
			end
		end
	end

	if last_send_command then
		if os.clock() - last_send_command["time"] < 0.45 then
			if style == 2 or style == 5 then
				local lines = 0
				for line in string.gmatch(text, "[^\n]+") do lines = lines + 1 end

				if lines > 0 then
					for index, value in ipairs(last_send_command["indexes"]) do
						if value[2] == false then
							if value[1] <= lines then
								local fix = (style == 2) and value[1] - 1 or value[1]
								sampSendDialogResponse(dialogId, 1, fix)
								last_send_command["time"] = os.clock()
								value[2] = true
								return false
							-- else
								-- chat(string.format("Строка под индексом #{HEX}%s{} не была найдена.", value[1]))
							end
						end
					end
				else last_send_command = false end
			else last_send_command = false end
		else last_send_command = false end
	end

	if string.match(title, "Авторизация") then
		entered_password = dialogId
		if not string.match(text, "Неверный пароль") and not string.match(text, "PIN") then
			local result, player_id = sampGetPlayerIdByCharHandle(playerPed)
			if result then
				local nickname = sampGetPlayerName(player_id)
				local nickname = string.gsub(nickname, "%[.+%]", "")
				local ip, port = sampGetCurrentServerAddress()
				local ip_adress = string.format("%s:%s", ip, port)
				if configuration["MANAGER"][ip_adress] and configuration["MANAGER"][ip_adress][nickname] then
					local password = configuration["MANAGER"][ip_adress][nickname]["password"]
					sampSendDialogResponse(dialogId, 1, 1, password)
					return false
				end
			end
		end
	end
end

function sampev.onSendChat(text)
	configuration["STATISTICS"]["message"] = configuration["STATISTICS"]["message"] + 1
	if not need_update_configuration then need_update_configuration = os.clock() end

	if string.len(text) > configuration["MAIN"]["characters_number"]["chat"] then
		if not last_on_send_value then
			last_on_send_value = { value, "", os.clock() }
		else
			if last_on_send_value[1] == value and last_on_send_value[2] == command and os.clock() - last_on_send_value[3] < 5 then
				last_on_send_value = false
				chat("Повторный ввод однотипного содержания был заблокирован.")
				return false
			else
				last_on_send_value = { value, "", os.clock() }
			end
		end

		local result = string_pairs(text, 86)
		for index, value in ipairs(result) do
			if index == 1 then
				sampSendChat(string.format("%s...", value))
			else
				sampSendChat(string.format("... %s", value))
			end
		end
		return false
	end
end

function sampev.onSendCommand(parametrs)
	local command, value
	if string.match(parametrs, "^/(%S+)[%s](.+)$") then 
		command, value = string.match(parametrs, "^/(%S+)[%s](.+)$") 
	else 
		command = string.match(parametrs, "^/(%S+)$") 
	end

	if command then
		if not configuration["STATISTICS"]["commands"][command] then
			configuration["STATISTICS"]["commands"][command] = 1
			if not need_update_configuration then need_update_configuration = os.clock() end
		else
			configuration["STATISTICS"]["commands"][command] = configuration["STATISTICS"]["commands"][command] + 1
			if not need_update_configuration then need_update_configuration = os.clock() end
		end

		if command == "lock" then
			if tonumber(value) then
				last_used_vehicle_key["type"] = tonumber(value)
				last_used_vehicle_key["time"] = os.time()
			end
		elseif command == "su" then
			local id, stars, reason = string.match(parametrs, "(%d+) (%d+) (.+)")
			t_last_suspect_parametrs = {id, stars, reason}
		end

		if value then
			local maximum_number_of_characters = maximum_number_of_characters()
			if maximum_number_of_characters[command] then
				if maximum_number_of_characters[command] < string.len(value) then
					if not last_on_send_value then
						last_on_send_value = { value, command, os.clock() }
					else
						if last_on_send_value[1] == value and last_on_send_value[2] == command and os.clock() - last_on_send_value[3] < 0.5 then
							last_on_send_value = false
							chat("Повторный ввод однотипного содержания был заблокирован.")
							return false
						else
							last_on_send_value = { value, command, os.clock() }
						end
					end

					if command == "me" then
						local result = string_pairs(value, maximum_number_of_characters[command] - 5)
						for index, value in ipairs(result) do
							if index == 1 then
								sampSendChat(string.format("/me %s...", value))
							else
								sampSendChat(string.format("/do ... %s", value))
							end
						end
					elseif command == "r" or command == "f" then
						local is_radio_type
						if command == "f" then
							if string.match(value, "^[1?2] (%S+)") then is_radio_type, value = string.match(value, "^(%d) (.+)") end
							if is_radio_type then command = string.format("%s %s", command, is_radio_type) end
						end

						if string.match(value, "%(%(%s(.+)%s%)%)") then
							local value = string.match(value, "%(%(%s(.+)%s%)%)")
							local result = string_pairs(value, maximum_number_of_characters[command] - 10)

							for index, value in ipairs(result) do
								if index == 1 then
									sampSendChat(string.format("/%s (( %s... ))", command, value))
								else
									sampSendChat(string.format("/%s (( ... %s ))", command, value))
								end
							end
						else
							local result = string_pairs(value, maximum_number_of_characters[command] - 5)
							for index, value in ipairs(result) do
								if index == 1 then
									sampSendChat(string.format("/%s %s...", command, value))
								else
									sampSendChat(string.format("/%s ... %s", command, value))
								end
							end
						end
					else
						local result = string_pairs(value, maximum_number_of_characters[command] - 5)
						for index, value in ipairs(result) do
							if index == 1 then
								sampSendChat(string.format("/%s %s...", command, value))
							else
								sampSendChat(string.format("/%s ... %s", command, value))
							end 
						end
					end return false
				end
			else
				if string.match(value, "(%d+)") then -- типа фаст проклик диалога 
					local ignore = { ["team"] = 1 }
					if not ignore[command] then
						last_send_command = {
							["send"] = command,
							["time"] = os.clock(), 
							["indexes"] = {}
						}

						if command == "anim" then
							if value == "0" or value == "79" then
								table.insert(last_send_command["indexes"], { 79, false })
								last_send_command["time"] = os.clock() + 1.5
								return { "/anim" }
							end
						else
							for index in string.gmatch(value, "(%d+)") do
								table.insert(last_send_command["indexes"], { tonumber(index), false })
							end
						end
					end
				end
			end
		end
	end
end

function sampev.onSetPlayerColor(player_id, color)
	if configuration["MAIN"]["settings"]["mask_timer"] then
		local result, id = sampGetPlayerIdByCharHandle(playerPed)
		if player_id == id then
			if color == 572662272 then
				configuration["STATISTICS"]["number_masks_used"] = configuration["STATISTICS"]["number_masks_used"] + 1
				if not need_update_configuration then need_update_configuration = os.clock() end
				create_player_text(2)
				handler_low_action("mask")  -- low rp
			else
				for index, value in ipairs(t_player_text) do
					if value and value["type"] == 2 then
						configuration["STATISTICS"]["time_using_mask"] = configuration["STATISTICS"]["time_using_mask"] + (os.clock() - value["clock"])
						if not need_update_configuration then need_update_configuration = os.clock() end
						table.remove(t_player_text, index)
						handler_low_action("unmask") -- low rp
					end
				end
			end
		end
	end
end

function sampev.onSendDialogResponse(dialogId, button, listboxId, input)
	if dialogId == 0 then
		if button == 1 and t_fuel_station[listboxId] then
			create_map_marker(t_fuel_station[listboxId])
			local x, y, z = getCharCoordinates(playerPed)
			local distance = getDistanceBetweenCoords3d(x, y, z, t_fuel_station[listboxId]["x"], t_fuel_station[listboxId]["y"], t_fuel_station[listboxId]["z"])
			chat(string.format("На вашем радаре отмечена {HEX}АЗС{}, расстояние до неё {HEX}%s{} м.", math.floor(distance)))
		end
	elseif dialogId == 101 then
		if button == 1 then
			if not (listboxId == 1 or listboxId == 2 or listboxId == 3 or listboxId == 9 or listboxId == 8) then
				sampSendDialogResponse(dialogId, button, listboxId, input)
				sampSendChat("/buy")
				return false
			end
		end
	elseif dialogId == 106 then
		sampSendChat("/buy")
		return false
	elseif dialogId == 247 then
		sampSendChat("/buy")
		return false
	elseif dialogId == 3079 then
		if list_of_orders["time"] then
			if ti_improved_dialogues[4]["status"] then
				list_of_orders["time"] = nil
				list_of_orders["point"] = listboxId + 1
				return {dialogId, button, list_of_orders["value"][listboxId + 1]["index"] - 1, input}
			end
		end
	elseif entered_password and dialogId == entered_password then
		local result, player_id = sampGetPlayerIdByCharHandle(playerPed)
		if result then
			local nickname = sampGetPlayerName(player_id)
			local nickname = string.gsub(nickname, "%[.+%]", "")
			local ip, port = sampGetCurrentServerAddress()
			local ip_adress = string.format("%s:%s", ip, port)

			if not (configuration["MANAGER"][ip_adress] and configuration["MANAGER"][ip_adress][nickname]) then
				entered_to_save_password = {ip_adress = ip_adress, nickname = nickname, password = input}
				chat("Для того, чтобы сохранить данный аккаунт в менеджере аккаунтов введите команду {HEX}/savepass{}.")
			else
				if string.match(sampGetDialogText(), "Неверный пароль") then
					entered_to_save_password = {ip_adress = ip_adress, nickname = nickname, password = input}
					chat("Для того, чтобы сохранить данный аккаунт в менеджере аккаунтов введите команду {HEX}/savepass{}.")
				end
			end
		end
		entered_password = nil
	elseif global_wanted and global_wanted["dialogId"] == dialogId then
		if button == 1 then
			local space = global_wanted
			global_wanted = nil
			if space["output"] and space["output"][listboxId + 1] and space["output"][listboxId + 1]["index"] then
				return {dialogId, button, space["output"][listboxId + 1]["index"] - 2, input}
			end
		end
	elseif t_quick_ads["time"] and (t_quick_ads["dialog_id"] and t_quick_ads["dialog_id"] == dialogId) then
		table.insert(configuration["ADS"], {
			received_ad = u8(t_quick_ads["ad"]),
			corrected_ad = u8(input),
			button = button,
			author = author,
			start_of_verification = t_quick_ads["time"],
			finish_of_verification = os.time()
		})

		t_quick_ads = {}

		if not need_update_configuration then need_update_configuration = os.clock() end
	end
end

function sampev.onSendTakeDamage(player_id, damage, weapon, bodypart)
	if isPlayerConnected(player_id) then
		last_damage_id = player_id
		local nickname = sampGetPlayerName(player_id)
		if sampGetDistanceToPlayer(player_id) <= 35 and sampGetPlayerColor(player_id) ~= 2236962 then
			preliminary_check_suspect(player_id, 1)
		end
	end
end

function sampev.onSendDeathNotification(reason, player_id)
	chat("Вам теперь доступна информация о возможности вернуться на место смерти ({HEX}/rkinfo{}).")
	delay_between_deaths = {calculateZone(), os.clock()}
end

function sampev.onBulletSync(suspect_id, data)
	if sampGetDistanceToPlayer(suspect_id) < 40 then
		local color = sampGetPlayerColor(suspect_id)
		if not sampIsPoliceOfficerById(suspect_id) then
			if data["targetType"] == 1 then -- вооружённое нападение
				if color ~= 2236962 and color ~= 4278190335 then
					if sampIsPoliceOfficerById(data["targetId"]) then
						preliminary_check_suspect(suspect_id, 1)
					else
						preliminary_check_suspect(suspect_id, 2)
					end
				end
			elseif data["targetType"] == 2 then
				local result, vehicle_handle = sampGetCarHandleBySampVehicleId(data["targetId"])
				if result then
					if isCharSittingInAnyCar(playerPed) and storeCarCharIsInNoSave(playerPed) == vehicle_handle then
						if color ~= 2236962 and color ~= 4278190335 then preliminary_check_suspect(suspect_id, 1) end
					else
						local is_vehicle_have_officer = false

						local result, passenger_number = getNumberOfPassengers(vehicle_handle)
						if result and passenger_number > 0 then
							for i = 0, getMaximumNumberOfPassengers(vehicle_handle) do
								if i == 3 then
									passenger = getDriverOfCar(vehicle_handle)
								else
									if not isCarPassengerSeatFree(vehicle_handle, i) then
											passenger = getCharInCarPassengerSeat(vehicle_handle, i)
									end
								end

								if sampIsPoliceOfficer(passenger) then is_vehicle_have_officer = true end
							end
						end

						if color ~= 2236962 and color ~= 4278190335 then
							if is_vehicle_have_officer then
								preliminary_check_suspect(suspect_id, 1)
							else
								preliminary_check_suspect(suspect_id, 2)
							end
						end
					end
				end
			end
		end
	end
end

function sampev.onSendEnterVehicle(vehicle_id, passenger)
	if not patrol_status["status"] then
		local result, handle = sampGetCarHandleBySampVehicleId(vehicle_id)
		if result and not passenger then
			local vehicle = "-596-597-598-599-601-427-528-415-523-490-"
			if string.match(vehicle, "%-" .. getCarModel(handle) .. "%-") then
				chat("Если Вы желаете активировать патрульного ассистента нажмите {HEX}Y{} или введите {HEX}/patrol{}.")
				create_offer(2, function() command_patrol() end)
			end
		end
	end
end

function sampev.onSetVehicleParamsEx(vehicle_id, parametrs, doors, windows)
	if last_used_vehicle_key["time"] then
		if os.time() - last_used_vehicle_key["time"] < 0.33 then
			if configuration["MAIN"]["settings"]["quick_lock_doors"] then
				local result, vehicle_handle = sampGetCarHandleBySampVehicleId(vehicle_id)
				if result then
					if getDistanceToVehicle(vehicle_handle) < 25 then
						if not (t_smart_vehicle["vehicle"][vehicle_id] and getCarModel(vehicle_handle) == t_smart_vehicle["vehicle"][vehicle_id]["model"]) then
							last_used_vehicle_key["time"] = false
							t_smart_vehicle["vehicle"][vehicle_id] = {
								model = getCarModel(vehicle_handle),
								type = last_used_vehicle_key["type"]
							}

							local normal_vehicle_id = getCarModel(vehicle_handle) - 399
							chat(string.format("Транспортное средство (%s {HEX}%s{} #{HEX}%s{}) теперь может быть открыто умным ключом.", tf_vehicle_type_name[3][t_vehicle_type[normal_vehicle_id]], t_vehicle_name[normal_vehicle_id], vehicle_id))
							chat("Для этого введите команду {HEX}/lock{} без параметров или нажмите клавишу {HEX}J{} рядом с транспортом.")
						end
					end
				end
			end
		end
	end
end

function sampev.onSetRaceCheckpoint(ltype, position, next_position, size)
	if list_of_orders["point"] then
		if list_of_orders["value"][list_of_orders["point"]] then
			local space, index = list_of_orders["value"][list_of_orders["point"]], ""
			if product_delivery_status == 1 then
				index = space["point_start"]
			elseif product_delivery_status == 2 then
				index = space["point_finish"]
			end
			if not t_points_completed_orders[index] then t_points_completed_orders[index] = position end
		end
	end
end

function sampev.onShowTextDraw(textdraw_id, another)
	if string.match(another["text"], "HARVESTING") then
		if not was_start_harvesting then 
			was_start_harvesting = { textdraw_id, os.clock() }
			chat("Для более удобного сбора урожая нажмите клавишу {HEX}H{} повторно.")
		end
	end
end

function sampev.onSetInterior(interior_id)
	if interior_id ~= 0 then 
		create_assistant_thread("quick_open_door")
	else
		destroy_assistant_thread("quick_open_door")
	end
end

function sampev.onSetVehicleVelocity(turn, velocity)
	if isCharSittingInAnyCar(playerPed) then
		local vehicle_handle = storeCarCharIsInNoSave(playerPed)
		local vehicle_vector_x, vehicle_vector_y, vehicle_vector_z = getCarSpeedVector(vehicle_handle)

		if vehicle_vector_x == 0 or vehicle_vector_y == 0 or vehicle_vector_z == 0 then 
			return false
		end

		if not isCarEngineOn(vehicle_handle) or not (isKeyDown(VK_W) or isKeyDown(VK_S)) then
			return false
		end

		local velocity_angle = math.deg(math.atan2(vehicle_vector_y - velocity["y"], vehicle_vector_x - velocity["x"]))
		local vehicle_angle = getCarHeading(vehicle_handle) + 90

		if velocity_angle < 0 then velocity_angle = 360 - math.abs(velocity_angle) end
		if vehicle_angle > 360 then vehicle_angle = vehicle_angle - 360 end

		local delta = 15

		if vehicle_angle - delta <= velocity_angle and vehicle_angle + delta >= velocity_angle then
			local distance = math.sqrt(velocity["x"]^2 + velocity["y"]^2 + velocity["z"]^2) 
			local k = distance / math.sqrt(vehicle_vector_x^2 + vehicle_vector_y^2 + vehicle_vector_z^2)

			velocity["x"] = vehicle_vector_x * k
			velocity["y"] = vehicle_vector_y * k
			velocity["z"] = vehicle_vector_z * k

			return { turn, velocity }
		else
			return false
		end
	end
end

function onScriptTerminate(script, bool)
	if thisScript() == script then
		script_is_alive = false
		configuration_save(configuration, true)

		-- отписываем системные команды (включая дублирующие n-команды)
		for index, value in ipairs(ti_system_commands) do
			sampUnregisterChatCommand(value["index"])
			sampUnregisterChatCommand("n" .. value["index"])
		end

		-- отписываем пользовательские команды и связанные с ними хоткеи
		if configuration["CUSTOM"] and configuration["CUSTOM"]["USERS"] and configuration["CUSTOM"]["USERS"]["main"] then
			for index, value in ipairs(configuration["CUSTOM"]["USERS"]["main"]) do
				if value["command"] and value["command"] ~= "" then
					sampUnregisterChatCommand(value["command"])
				end
				if value["keys"] and value["keys"]["v"] then
					local result, id = rkeys.isHotKeyDefined(value["keys"]["v"])
					if result then rkeys.unRegisterHotKey(id) end
				end
			end
		end

		sampUnregisterChatCommand("fix_ad")

		for index, value in ipairs(t_map_markers) do
			if value["marker"] then removeBlip(value["marker"]) end
			if value["point3"] then removeUser3dMarker(value["point3"]) end
		end

		if t_entity_marker[1] then removeBlip(t_entity_marker[1]) end 

			end
end
-- !event

-- https
function checking_relevance_versions_and_files()
	player_serial_number = tostring(getSerialNumber())

	local responce = https.request("https://raw.githubusercontent.com/zak0nov/helper-for-aviero/main/versions.json")
	print("==== VERSIONS.JSON ====")
    print(responce)
    print("==== END ====")
	if responce then
		local versions = decodeJson(responce)
		if versions["MAIN"]["version"] == thisScript().version then
			chat(string.format("Игровой помощник был успешно загружен. Вы используете актуальную версию ({HEX}%s{}).", thisScript().version))

			if versions["NPA-GREEN"]["version"] ~= configuration["DOCUMENTS"]["version"] then
				local ip = sampGetCurrentServerAddress()
				local url = string.format("https://raw.githubusercontent.com/zak0nov/helper-for-aviero/main/%s.json", ip)
				local result = https.request(url)
				if result then
					local documents = decodeJson(result)
					for k, document in ipairs(documents) do
						for article, value in ipairs(document["content"]) do
							local treenode_article = u8:decode(string.format(u8"Статья %s | %s", article, value["title"]))
							if string.len(treenode_article) > 80 then
								treenode_article = string_pairs(treenode_article, 90)[1] .. " .."
							end

							document["content"][article]["treenode_article"] = u8(treenode_article)

							for part, lvalue in ipairs(value["content"]) do
								local treenode_part = u8:decode(string.format(u8"Часть %s. %s", part, lvalue["title"]))
								if string.len(treenode_part) > 80 then
									treenode_part = string_pairs(treenode_part, 80)[1] .. " .."
								end

								hint_index = string.format("##part-%s-%s", article, part)
								hint_value = table.concat(string_pairs(lvalue["title"], 140), "\n")

								document["content"][article]["content"][part]["treenode_part"] = u8(treenode_part)
								document["content"][article]["content"][part]["hint_index"] = hint_index
								document["content"][article]["content"][part]["hint_value"] = hint_value
							end
						end
					end

					if not configuration["DOCUMENTS"]["content"] then configuration["DOCUMENTS"]["content"] = {} end
					configuration["DOCUMENTS"]["content"] = documents
					configuration["DOCUMENTS"]["version"] = versions["NPA-GREEN"]["version"]
					if not need_update_configuration then need_update_configuration = os.clock() end
				end
			end

			if versions["USERS"]["version"] ~= configuration["USERS"]["version"] then
				local result = https.request(versions["USERS"]["url"])
				if not string.match(result, "500: Internal Server Error") then
					local result = decodeJson(result)
					if result and type(result) == "table" then
						configuration["USERS"]["version"] = versions["USERS"]["version"]
						configuration["USERS"]["content"] = result
					else chat("Произошла ошибка при попытке получить информацию о пользователях. Код ошибки: #2.") end
				else chat("Произошла ошибка при попытке получить информацию о пользователях. Код ошибки: #1.") end
			end

			if configuration["USERS"]["content"] then
				local result, player_id = sampGetPlayerIdByCharHandle(playerPed)
				local player_nickname = sampGetPlayerName(player_id)

				for index, value in pairs(configuration["USERS"]["content"]) do
					for user_serial in string.gmatch(value["serialNumber"], "[^,%s]+") do
						if user_serial == player_serial_number then
							local day = math.floor((value["subscription"] - os.time()) / 3600 / 24)
							if day > 0 then
								local date = os.date("%d.%m.%Y", value["subscription"])
								chat(("Вы авторизовались как %s%s{}, профиль верифицирован до {HEX}%s{} ({HEX}%s{} дней)."):format(value["color"], string.nlower(u8:decode(value["rang"])), date, day))
								player_status = value["rangNumber"]
								-- send_bot(string.format(u8"(%s) %s авторизовался как верифицированный пользователь (%s уровень).", thisScript().version, player_nickname, value["rangNumber"]))
							else
								chat("Верификация вашего профиля истекла, обратитесь к разработчику для её продления.")
								-- send_bot(string.format(u8"(%s) %s авторизовался как неверифицированный пользователь.", thisScript().version, player_nickname))
							end
						end 
					end
				end

				if player_status == 0 then
					chat("Ваш профиль не верифицирован, определённая часть функционала Вам недоступна.")
					-- send_bot(string.format(u8"(%s) %s авторизовался как неверифицированный пользователь.", thisScript().version, player_nickname))
				end
			end

			chat("Хотите что-то изменить или добавить в помощник? Пишите в личные сообщения {HEX}vk.com/wojciechk{}.")
		else
			local file = https.request(versions["MAIN"]["url"])
			if file then
				chat("Игровой помощник был автоматически обновлён до новейшей версии. Подробнее в разделе новостей ({HEX}/mh{}).")
				local file_text = u8:decode(file)
				local file = io.open(thisScript().path, "w")
				file:write(file_text)
				file:close()
			else chat("Произошла ошибка при попытке обновления игрового помощника. Код ошибки: #2.") end
		end
	end
end

function speller(text)
	local url = string.format("https://speller.yandex.net/services/spellservice.json/checkText?text=%s", urlencode(u8(text)))
	local result = https.request(url)
	return result and decodeJson(result)
end 
-- !https




