extends RefCounted
## Ülkenin isim kültürüne göre (deterministik) rastgele kişi adı üretir.
## Gerçek bakan/lider isimleri bittiğinde (yıllar geçince) bu isimler kullanılır.
## Aynı (anahtar) her zaman aynı ismi verir; böylece kayıt dosyasında isim saklamaya gerek kalmaz.

# kültür -> [erkek adlar, kadın adlar, soyadlar, soyadı-önce mi]
const POOLS := {
	"tr": [["Ahmet", "Mehmet", "Mustafa", "Ali", "Hasan", "Hüseyin", "İbrahim", "Murat", "Kemal", "Emre", "Burak", "Selim", "Cem", "Orhan", "Volkan", "Levent"],
		["Ayşe", "Fatma", "Emine", "Zeynep", "Elif", "Hatice", "Merve", "Selin", "Esra", "Derya", "Gül", "Nermin", "Sevgi", "Pınar"],
		["Yılmaz", "Kaya", "Demir", "Şahin", "Çelik", "Yıldız", "Aydın", "Özdemir", "Arslan", "Doğan", "Kılıç", "Aslan", "Çetin", "Koç", "Kurt", "Özkan", "Polat", "Erdem", "Güneş", "Korkmaz"], false],
	"ar": [["Mohammed", "Ahmed", "Mahmoud", "Khalid", "Omar", "Youssef", "Hassan", "Ali", "Ibrahim", "Tariq", "Samir", "Nabil", "Faisal", "Karim", "Walid", "Hamad", "Rashid", "Adel"],
		["Fatima", "Aisha", "Layla", "Mariam", "Noura", "Huda", "Salma", "Rania", "Amal", "Dina", "Samira", "Yasmin", "Lamia"],
		["Al-Hakim", "Al-Masri", "Al-Farsi", "Haddad", "Mansour", "Khalil", "Saleh", "Nasser", "Al-Said", "Darwish", "Al-Rashid", "Bakr", "Qasim", "Al-Najjar", "Hamdan", "Suleiman", "Abbas", "Jaber", "Al-Zahrani", "Ghanem"], false],
	"fa": [["Reza", "Hossein", "Mehdi", "Ali", "Hamid", "Majid", "Mojtaba", "Kaveh", "Davood", "Farhad", "Saeed", "Behnam"],
		["Zahra", "Maryam", "Fatemeh", "Shirin", "Leila", "Narges", "Parvin", "Mina", "Soheila"],
		["Hosseini", "Rezaei", "Karimi", "Mousavi", "Ahmadi", "Jafari", "Rahimi", "Kazemi", "Ghorbani", "Tehrani", "Shirazi", "Sadeghi", "Mohammadi", "Naderi"], false],
	"ru": [["Aleksandr", "Sergey", "Dmitry", "Andrey", "Aleksey", "Igor", "Vladimir", "Nikolay", "Pavel", "Viktor", "Mikhail", "Oleg", "Yuri", "Anatoly", "Konstantin", "Boris"],
		["Elena", "Olga", "Natalia", "Tatyana", "Irina", "Svetlana", "Marina", "Anna", "Galina", "Lyudmila"],
		["Ivanov", "Petrov", "Smirnov", "Kuznetsov", "Popov", "Sokolov", "Lebedev", "Kozlov", "Novikov", "Morozov", "Volkov", "Solovyov", "Vasiliev", "Zaytsev", "Pavlov", "Fedorov", "Mikhailov", "Belov", "Orlov", "Medvedev"], false],
	"sl": [["Marko", "Nikola", "Ivan", "Stefan", "Milan", "Petar", "Dragan", "Zoran", "Miroslav", "Aleksandar", "Goran", "Darko", "Tomislav", "Bogdan"],
		["Ana", "Marija", "Jelena", "Ivana", "Milica", "Katarina", "Dragana", "Mirjana", "Snežana", "Vesna"],
		["Jovanović", "Petrović", "Nikolić", "Marković", "Đorđević", "Stojanović", "Ilić", "Kovačević", "Babić", "Horvat", "Novak", "Pavlović", "Todorović", "Lukić", "Savić", "Radić", "Matić", "Vuković"], false],
	"pl": [["Piotr", "Tomasz", "Marek", "Andrzej", "Krzysztof", "Paweł", "Jan", "Michał", "Stanisław", "Wojciech", "Adam", "Jacek"],
		["Anna", "Katarzyna", "Małgorzata", "Agnieszka", "Barbara", "Ewa", "Joanna", "Magdalena", "Zofia"],
		["Kowalski", "Nowak", "Wiśniewski", "Wójcik", "Kowalczyk", "Kamiński", "Lewandowski", "Zieliński", "Szymański", "Woźniak", "Dąbrowski", "Kozłowski", "Jankowski", "Mazur", "Krawczyk"], false],
	"cz": [["Jan", "Petr", "Pavel", "Tomáš", "Martin", "Jiří", "Josef", "Milan", "Karel", "Lukáš", "Ondřej", "Zdeněk"],
		["Jana", "Marie", "Eva", "Hana", "Lenka", "Petra", "Alena", "Lucie", "Kateřina"],
		["Novák", "Svoboda", "Dvořák", "Černý", "Procházka", "Kučera", "Veselý", "Horák", "Němec", "Marek", "Pokorný", "Král", "Beneš", "Fiala", "Sedláček"], false],
	"hu": [["László", "István", "Gábor", "Zoltán", "Péter", "András", "Tamás", "Balázs", "Ferenc", "Viktor", "Attila", "Csaba"],
		["Katalin", "Judit", "Zsuzsanna", "Erzsébet", "Ilona", "Réka", "Orsolya", "Eszter"],
		["Nagy", "Kovács", "Tóth", "Szabó", "Horváth", "Varga", "Kiss", "Molnár", "Németh", "Farkas", "Balogh", "Papp", "Takács", "Juhász"], true],
	"ro": [["Andrei", "Mihai", "Ion", "Cristian", "Radu", "Vasile", "Gheorghe", "Florin", "Marius", "Sorin", "Bogdan", "Ștefan"],
		["Maria", "Elena", "Ioana", "Andreea", "Cristina", "Mihaela", "Daniela", "Laura", "Ana"],
		["Popescu", "Ionescu", "Popa", "Stan", "Dumitru", "Constantin", "Munteanu", "Radu", "Moldovan", "Stoica", "Georgescu", "Dinu", "Marinescu", "Preda"], false],
	"de": [["Thomas", "Michael", "Andreas", "Stefan", "Markus", "Jürgen", "Klaus", "Peter", "Hans", "Matthias", "Florian", "Lukas", "Wolfgang", "Dieter"],
		["Anna", "Petra", "Sabine", "Monika", "Claudia", "Katrin", "Julia", "Ursula", "Heike", "Birgit", "Lena"],
		["Müller", "Schmidt", "Schneider", "Fischer", "Weber", "Meyer", "Wagner", "Becker", "Schulz", "Hoffmann", "Koch", "Richter", "Klein", "Wolf", "Neumann", "Braun", "Krüger", "Hofmann"], false],
	"nl": [["Jan", "Pieter", "Willem", "Henk", "Johan", "Maarten", "Bas", "Joost", "Rob", "Wouter"],
		["Anne", "Marieke", "Ingrid", "Sanne", "Femke", "Lotte", "Carla", "Els"],
		["de Vries", "van den Berg", "Bakker", "Janssen", "Visser", "Smit", "Meijer", "de Boer", "Mulder", "de Jong", "Bos", "Vos", "Peters", "Hendriks"], false],
	"nd": [["Lars", "Erik", "Anders", "Magnus", "Olav", "Henrik", "Jens", "Mikael", "Nils", "Bjørn", "Sven", "Kristian", "Matti", "Jukka"],
		["Ingrid", "Kari", "Anna", "Maria", "Sofie", "Helga", "Astrid", "Liv", "Eva", "Sanna", "Laura"],
		["Hansen", "Johansen", "Andersen", "Nielsen", "Larsen", "Olsen", "Berg", "Lindqvist", "Svensson", "Karlsson", "Virtanen", "Korhonen", "Jensen", "Eriksen", "Nilsson"], false],
	"fr": [["Jean", "Pierre", "Michel", "Philippe", "Alain", "Laurent", "François", "Nicolas", "Thierry", "Olivier", "Éric", "Julien", "Bruno"],
		["Marie", "Isabelle", "Catherine", "Nathalie", "Sophie", "Sylvie", "Anne", "Claire", "Valérie", "Hélène"],
		["Martin", "Bernard", "Dubois", "Thomas", "Robert", "Richard", "Petit", "Durand", "Leroy", "Moreau", "Simon", "Laurent", "Lefebvre", "Michel", "Garcia", "David", "Bertrand", "Roux", "Vincent", "Fournier"], false],
	"es": [["José", "Juan", "Carlos", "Luis", "Miguel", "Javier", "Antonio", "Francisco", "Manuel", "Alberto", "Fernando", "Ricardo", "Jorge", "Diego", "Pablo"],
		["María", "Carmen", "Ana", "Isabel", "Laura", "Marta", "Lucía", "Patricia", "Elena", "Rosa", "Teresa"],
		["García", "Rodríguez", "Martínez", "López", "González", "Pérez", "Sánchez", "Ramírez", "Torres", "Flores", "Díaz", "Vargas", "Castro", "Romero", "Herrera", "Mendoza", "Ortega", "Silva", "Rojas", "Morales"], false],
	"pt": [["João", "José", "António", "Pedro", "Paulo", "Carlos", "Manuel", "Rui", "Miguel", "Luís", "Ricardo", "Tiago"],
		["Maria", "Ana", "Teresa", "Inês", "Sofia", "Catarina", "Beatriz", "Helena", "Rita"],
		["Silva", "Santos", "Ferreira", "Pereira", "Oliveira", "Costa", "Rodrigues", "Martins", "Sousa", "Fernandes", "Gonçalves", "Carvalho", "Almeida", "Ribeiro"], false],
	"it": [["Giuseppe", "Giovanni", "Marco", "Luca", "Andrea", "Paolo", "Antonio", "Francesco", "Stefano", "Roberto", "Alessandro", "Massimo", "Enrico"],
		["Maria", "Anna", "Giulia", "Francesca", "Chiara", "Elena", "Paola", "Laura", "Silvia", "Lucia"],
		["Rossi", "Russo", "Ferrari", "Esposito", "Bianchi", "Romano", "Colombo", "Ricci", "Marino", "Greco", "Bruno", "Gallo", "Conti", "De Luca", "Mancini", "Costa"], false],
	"en": [["James", "John", "Robert", "Michael", "David", "William", "Richard", "Thomas", "Daniel", "Andrew", "Peter", "Mark", "Paul", "Stephen", "Mathew"],
		["Mary", "Susan", "Karen", "Sarah", "Emma", "Jennifer", "Linda", "Rebecca", "Helen", "Claire", "Laura"],
		["Smith", "Johnson", "Williams", "Brown", "Jones", "Miller", "Davis", "Wilson", "Taylor", "Anderson", "Thompson", "Walker", "Hall", "Allen", "Young", "King", "Wright", "Scott", "Green", "Baker"], false],
	"gr": [["Giorgos", "Dimitris", "Nikos", "Kostas", "Yannis", "Panagiotis", "Christos", "Thanasis", "Vasilis", "Stavros"],
		["Maria", "Eleni", "Katerina", "Sofia", "Georgia", "Anna", "Despina", "Ioanna"],
		["Papadopoulos", "Georgiou", "Nikolaou", "Dimitriou", "Karagiannis", "Vasiliou", "Pappas", "Alexiou", "Makris", "Antoniou", "Christodoulou", "Konstantinou"], false],
	"he": [["David", "Moshe", "Yossi", "Avi", "Eli", "Amir", "Yaakov", "Daniel", "Ron", "Uri", "Noam", "Itai"],
		["Sara", "Rachel", "Miriam", "Tamar", "Noa", "Shira", "Yael", "Michal", "Dana"],
		["Cohen", "Levi", "Mizrahi", "Peretz", "Biton", "Dahan", "Avraham", "Friedman", "Katz", "Shapira", "Goldberg", "Azoulay", "Ben-David"], false],
	"ka": [["Giorgi", "Levan", "Nikoloz", "Davit", "Irakli", "Zurab", "Tamaz", "Gela", "Vakhtang", "Aram", "Armen", "Vahe", "Hovhannes", "Karen", "Tigran"],
		["Nino", "Tamar", "Ketevan", "Mariam", "Nana", "Lia", "Anahit", "Lusine", "Narine", "Arpine"],
		["Beridze", "Kapanadze", "Gelashvili", "Maisuradze", "Lomidze", "Chkheidze", "Sargsyan", "Grigoryan", "Hakobyan", "Harutyunyan", "Petrosyan", "Avetisyan"], false],
	"az": [["Elchin", "Rashad", "Farid", "Kamran", "Orkhan", "Vugar", "Tural", "Rovshan", "Samir", "Ilham"],
		["Aygun", "Leyla", "Nigar", "Gunel", "Sevda", "Zeynab", "Arzu"],
		["Aliyev", "Mammadov", "Hasanov", "Huseynov", "Guliyev", "Ismayilov", "Abdullayev", "Rahimov", "Safarov"], false],
	"tk": [["Nurlan", "Bakyt", "Askar", "Daulet", "Marat", "Timur", "Rustam", "Bakhtiyor", "Farkhod", "Serdar", "Berdy", "Azamat"],
		["Aigul", "Gulnara", "Dilnoza", "Madina", "Zarina", "Aizada", "Saltanat", "Nargiza", "Ogulgerek"],
		["Nazarbayev", "Karimov", "Rakhmonov", "Akayev", "Tokayev", "Sultanov", "Mamedov", "Rakhimov", "Ismailov", "Satybaldiev", "Berdimuhamedov", "Yuldashev", "Kasymov"], false],
	"mn": [["Bat", "Temuujin", "Ganbold", "Enkh", "Tumur", "Sukh", "Bold", "Naran", "Gantulga", "Batbayar"],
		["Oyun", "Solongo", "Narantuya", "Bolor", "Khulan", "Saran", "Tsetseg", "Altantsetseg"],
		["Batbayar", "Ganbaatar", "Dorj", "Erdene", "Purev", "Tsogt", "Chuluun", "Munkh-Erdene", "Baatar", "Jargal"], false],
	"zh": [["Wei", "Jun", "Lei", "Qiang", "Ming", "Jian", "Hao", "Tao", "Bo", "Peng", "Gang", "Yong", "Hui", "Chao"],
		["Li", "Fang", "Jing", "Min", "Yan", "Xiu", "Ling", "Mei", "Hua", "Juan", "Xia"],
		["Wang", "Li", "Zhang", "Liu", "Chen", "Yang", "Huang", "Zhao", "Zhou", "Wu", "Xu", "Sun", "Ma", "Zhu", "Hu", "Guo", "He", "Lin", "Gao", "Luo"], true],
	"ja": [["Hiroshi", "Takashi", "Kenji", "Satoshi", "Akira", "Yuki", "Taro", "Daisuke", "Masaru", "Koji", "Shinji", "Naoki", "Ryo"],
		["Yoko", "Keiko", "Yuko", "Akiko", "Naoko", "Mariko", "Sachiko", "Tomoko", "Emi"],
		["Sato", "Suzuki", "Takahashi", "Tanaka", "Watanabe", "Ito", "Yamamoto", "Nakamura", "Kobayashi", "Kato", "Yoshida", "Yamada", "Sasaki", "Matsumoto", "Inoue"], true],
	"ko": [["Min-jun", "Seo-jun", "Ji-hoon", "Hyun-woo", "Dong-hyun", "Sung-min", "Jae-won", "Tae-yang", "Young-ho", "Joon-ho", "Sang-woo"],
		["Ji-woo", "Soo-ah", "Eun-ji", "Min-seo", "Hye-jin", "Yu-na", "Seo-yeon", "Mi-sook"],
		["Kim", "Lee", "Park", "Choi", "Jung", "Kang", "Cho", "Yoon", "Jang", "Lim", "Han", "Oh", "Shin", "Seo"], true],
	"vn": [["Minh", "Hung", "Tuan", "Dung", "Nam", "Long", "Quang", "Thanh", "Khoa", "Duc", "Hai", "Phong"],
		["Lan", "Huong", "Mai", "Linh", "Thu", "Ngoc", "Hoa", "Trang", "Anh"],
		["Nguyễn", "Trần", "Lê", "Phạm", "Hoàng", "Vũ", "Đặng", "Bùi", "Đỗ", "Ngô", "Dương", "Lý"], true],
	"th": [["Somchai", "Anan", "Prasert", "Suriya", "Chaiwat", "Kittipong", "Narong", "Wichai", "Thanakorn", "Apichat"],
		["Siriporn", "Malee", "Supaporn", "Nattaya", "Kanya", "Pimchanok", "Ratana", "Warunee"],
		["Wongsakul", "Srisuwan", "Chaiyasit", "Phromma", "Boonmee", "Rattanakosin", "Saetang", "Kaewmanee", "Thongchai", "Suksawat"], false],
	"id": [["Budi", "Agus", "Hendra", "Joko", "Bambang", "Rudi", "Wahyu", "Dedi", "Eko", "Ahmad", "Hadi", "Syafruddin", "Abdul", "Razak"],
		["Siti", "Dewi", "Sri", "Ratna", "Putri", "Wulan", "Rina", "Nur", "Aminah", "Farah"],
		["Santoso", "Wijaya", "Susanto", "Hidayat", "Pratama", "Saputra", "Nugroho", "Kurniawan", "Rahman", "Hakim", "Ismail", "Yusof", "Lim", "Tan"], false],
	"in": [["Rajesh", "Amit", "Sanjay", "Vijay", "Anil", "Sunil", "Rahul", "Manoj", "Vikram", "Arun", "Prakash", "Suresh", "Ravi", "Deepak"],
		["Priya", "Sunita", "Anita", "Meena", "Kavita", "Neha", "Pooja", "Sushma", "Lakshmi", "Radha"],
		["Sharma", "Verma", "Gupta", "Singh", "Kumar", "Patel", "Reddy", "Iyer", "Nair", "Mehta", "Joshi", "Rao", "Chatterjee", "Banerjee", "Desai", "Mishra"], false],
	"ur": [["Imran", "Nawaz", "Asif", "Tariq", "Faisal", "Bilal", "Usman", "Kamran", "Zahid", "Shahid", "Rafiq", "Khalid", "Mujibur", "Anwar"],
		["Ayesha", "Fatima", "Sana", "Nadia", "Hina", "Rubina", "Shabnam", "Nasreen", "Sultana"],
		["Khan", "Ahmed", "Hussain", "Malik", "Chaudhry", "Sheikh", "Qureshi", "Siddiqui", "Rahman", "Islam", "Hossain", "Mirza", "Butt", "Bhutto"], false],
	"sw": [["Juma", "Hamisi", "Baraka", "Omari", "Joseph", "Daniel", "Peter", "Samuel", "Kevin", "Hassan", "Moses", "Elias", "Ibrahim", "Isaac"],
		["Amina", "Grace", "Mary", "Rehema", "Neema", "Zawadi", "Esther", "Fatuma", "Janet", "Joyce"],
		["Mwangi", "Otieno", "Kamau", "Mushi", "Kimaro", "Wanjiru", "Odhiambo", "Mutua", "Kiprop", "Ssemwogerere", "Okello", "Nkurunziza", "Habimana", "Mugabo"], false],
	"wa": [["Kwame", "Kofi", "Emeka", "Chinedu", "Tunde", "Segun", "Ibrahim", "Musa", "Abubakar", "Yaw", "Femi", "Chidi", "Seyni", "Mamadou", "Boubacar", "Ousmane"],
		["Ama", "Abena", "Ngozi", "Chioma", "Funmi", "Aisha", "Adaeze", "Fatou", "Aminata", "Mariama", "Kadiatou"],
		["Mensah", "Owusu", "Boateng", "Okafor", "Adeyemi", "Bello", "Okonkwo", "Balogun", "Eze", "Diallo", "Traoré", "Konaté", "Camara", "Sow", "Ndiaye", "Koné", "Ouédraogo", "Sylla"], false],
	"cf": [["Jean-Claude", "Pierre", "Joseph", "Emmanuel", "Paul", "Théodore", "Ange", "Désiré", "Prosper", "Fidèle", "Honoré", "Faustin"],
		["Marie", "Béatrice", "Jeanne", "Solange", "Rose", "Odette", "Pauline", "Clémence"],
		["Kabila", "Mbemba", "Ndong", "Obiang", "Nzamba", "Kouassi", "Bongo", "Mukendi", "Tshisekedi", "Onana", "Etoundi", "Dossou", "Gnassingbé", "Yao", "Kouadio", "Mavungu"], false],
	"am": [["Abebe", "Tesfaye", "Getachew", "Dawit", "Yonas", "Berhanu", "Mulugeta", "Haile", "Samuel", "Girma", "Isaias", "Ahmed"],
		["Almaz", "Tigist", "Selam", "Meseret", "Hirut", "Aster", "Birtukan", "Fatuma", "Halima"],
		["Tadesse", "Bekele", "Alemu", "Gebre", "Mengistu", "Tesfaye", "Desta", "Kebede", "Hailemariam", "Abdi", "Warsame", "Yusuf"], false],
	"sa": [["Thabo", "Sipho", "Mandla", "Tshepo", "Lungile", "Bheki", "Kagiso", "Tendai", "Farai", "Neo", "Themba", "Lebo", "Itumeleng", "Siphiwe"],
		["Nomsa", "Thandi", "Lerato", "Zanele", "Palesa", "Naledi", "Rudo", "Chipo", "Busisiwe", "Mpho"],
		["Dlamini", "Nkosi", "Khumalo", "Ndlovu", "Moyo", "Sibanda", "Mokoena", "Molefe", "Phiri", "Banda", "Chirwa", "Mbeki", "Tshabalala", "Masire"], false],
	"mg": [["Andry", "Hery", "Rivo", "Tojo", "Faly", "Rado", "Njaka", "Mamy", "Jean", "Eric"],
		["Voahangy", "Lalao", "Hanta", "Soa", "Nirina", "Mialy", "Fara", "Sahondra"],
		["Rajoelina", "Ravalomanana", "Rakotoarisoa", "Randrianasolo", "Rasolofo", "Andrianarivo", "Razafy", "Ratsiraka", "Rabe"], false],
	"pc": [["Ioane", "Semisi", "Sione", "Tevita", "Viliami", "Peni", "Josaia", "Manu", "Tui", "Kalolo", "Taufa", "Lotu"],
		["Mere", "Litia", "Lupe", "Sina", "Losana", "Ana", "Mele", "Seini"],
		["Tuilagi", "Vaka", "Naidu", "Ratu", "Fonoti", "Tupou", "Tuivaga", "Wesley", "Taumoepeau", "Kauhalalalo", "Moala", "Seruiratu"], false],
	"mk": [["Ali", "Abdullah", "Ahmad", "Hussein", "Salman", "Ismail", "Zainal", "Azman", "Rizal", "Halim", "Roslan", "Aziz"],
		["Nurul", "Aishah", "Farah", "Zainab", "Aminah", "Rohani", "Siti", "Hajar"],
		["bin Abdullah", "bin Hassan", "bin Ismail", "Al-Haj", "bin Yusof", "bin Salleh", "bin Omar", "Rahman", "bin Ahmad", "bin Ibrahim"], false],
}

# ülke (name_en) -> kültür; listede yoksa kıtaya göre varsayılan seçilir
const CULTURE_OF := {
	"Turkey": "tr", "N. Cyprus": "tr", "Cyprus": "gr", "Greece": "gr", "Israel": "he", "Iran": "fa", "Afghanistan": "fa",
	"Tajikistan": "fa", "Russia": "ru", "Belarus": "ru", "Ukraine": "ru", "Moldova": "ro", "Romania": "ro",
	"Poland": "pl", "Czechia": "cz", "Slovakia": "cz", "Hungary": "hu",
	"Serbia": "sl", "Croatia": "sl", "Bosnia and Herz.": "sl", "Montenegro": "sl", "Slovenia": "sl", "North Macedonia": "sl", "Bulgaria": "sl", "Kosovo": "sl", "Albania": "sl",
	"Germany": "de", "Austria": "de", "Switzerland": "de", "Liechtenstein": "de", "Luxembourg": "de",
	"Netherlands": "nl", "Belgium": "nl", "Sweden": "nd", "Norway": "nd", "Denmark": "nd", "Finland": "nd", "Iceland": "nd", "Greenland": "nd", "Estonia": "nd", "Latvia": "nd", "Lithuania": "nd",
	"France": "fr", "Monaco": "fr", "Italy": "it", "San Marino": "it", "Malta": "it", "Spain": "es", "Andorra": "es", "Portugal": "pt", "Brazil": "pt", "Angola": "pt", "Mozambique": "pt", "Guinea-Bissau": "pt", "Cabo Verde": "pt", "São Tomé and Principe": "pt", "Timor-Leste": "pt",
	"United States of America": "en", "United Kingdom": "en", "Canada": "en", "Australia": "en", "New Zealand": "en", "Ireland": "en",
	"Georgia": "ka", "Armenia": "ka", "Azerbaijan": "az", "Kazakhstan": "tk", "Uzbekistan": "tk", "Kyrgyzstan": "tk", "Turkmenistan": "tk", "Mongolia": "mn",
	"China": "zh", "Taiwan": "zh", "Singapore": "zh", "Japan": "ja", "South Korea": "ko", "North Korea": "ko", "Vietnam": "vn",
	"Thailand": "th", "Laos": "th", "Cambodia": "th", "Myanmar": "th", "Indonesia": "id", "Malaysia": "mk", "Brunei": "mk",
	"India": "in", "Nepal": "in", "Bhutan": "in", "Sri Lanka": "in", "Pakistan": "ur", "Bangladesh": "ur", "Maldives": "ur",
	"Ethiopia": "am", "Eritrea": "am", "Somalia": "am", "Somaliland": "am", "Djibouti": "am",
	"Kenya": "sw", "Tanzania": "sw", "Uganda": "sw", "Rwanda": "sw", "Burundi": "sw", "Comoros": "sw", "Seychelles": "sw",
	"Nigeria": "wa", "Ghana": "wa", "Senegal": "wa", "Mali": "wa", "Niger": "wa", "Burkina Faso": "wa", "Guinea": "wa", "Sierra Leone": "wa", "Liberia": "wa", "Gambia": "wa", "Togo": "wa", "Benin": "wa", "Mauritania": "wa", "Chad": "wa",
	"Dem. Rep. Congo": "cf", "Congo": "cf", "Cameroon": "cf", "Gabon": "cf", "Eq. Guinea": "cf", "Central African Rep.": "cf", "Côte d'Ivoire": "cf",
	"South Africa": "sa", "Zimbabwe": "sa", "Zambia": "sa", "Malawi": "sa", "Botswana": "sa", "Namibia": "sa", "Lesotho": "sa", "eSwatini": "sa", "Mauritius": "sa",
	"Madagascar": "mg", "Fiji": "pc", "Papua New Guinea": "pc", "Solomon Is.": "pc", "Vanuatu": "pc", "Samoa": "pc", "Tonga": "pc", "Kiribati": "pc", "Micronesia": "pc", "Marshall Is.": "pc", "Palau": "pc", "Nauru": "pc", "Tuvalu": "pc",
	"Jamaica": "en", "Trinidad and Tobago": "en", "Guyana": "en", "Belize": "en", "Bahamas": "en", "Barbados": "en", "Saint Lucia": "en", "Grenada": "en", "St. Vin. and Gren.": "en", "Antigua and Barb.": "en", "Dominica": "en", "St. Kitts and Nevis": "en",
	"Suriname": "nl", "S. Sudan": "sw", "Sudan": "ar", "Libya": "ar", "Algeria": "ar", "Tunisia": "ar", "Morocco": "ar", "W. Sahara": "ar", "Egypt": "ar",
}
const ARAB := ["Saudi Arabia", "United Arab Emirates", "Qatar", "Kuwait", "Bahrain", "Oman", "Yemen", "Jordan", "Lebanon", "Syria", "Iraq", "Palestine"]


static func culture_of(c) -> String:
	var n: String = c.name_en
	if CULTURE_OF.has(n):
		return CULTURE_OF[n]
	if n in ARAB:
		return "ar"
	var cont: String = str(c.get("continent")) if c.get("continent") != null else ""
	match cont:
		"Africa": return "wa"
		"Asia": return "in"
		"South America", "North America": return "es"
		"Oceania": return "pc"
		"Europe": return "en"
	return "en"


## key: aynı anahtar aynı kişiyi üretir (ülke+rol+dönem gibi)
static func person(culture: String, key: String, female: bool) -> String:
	var pool: Array = POOLS.get(culture, POOLS["en"])
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key)
	var given: String = (pool[1] if female else pool[0])[rng.randi() % (pool[1] if female else pool[0]).size()]
	var sur: String = pool[2][rng.randi() % pool[2].size()]
	if female:
		sur = _fem_surname(culture, sur)
	return "%s %s" % ([sur, given] if pool[3] else [given, sur])


static func is_female(key: String, chance: float = 0.22) -> bool:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("g:" + key)
	return rng.randf() < chance


static func _fem_surname(culture: String, s: String) -> String:
	match culture:
		"ru":
			for suf in ["ov", "ev", "in"]:
				if s.ends_with(suf):
					return s + "a"
		"pl":
			if s.ends_with("ski"):
				return s.trim_suffix("ski") + "ska"
		"cz":
			if s.ends_with("ý"):
				return s.trim_suffix("ý") + "á"
			return s + "ová"
	return s
