public struct StateDistricts: Identifiable, Hashable, Sendable {
    public var id: String { stateName }
    public let stateName: String
    public let districts: [String]
    
    public init(stateName: String, districts: [String]) {
        self.stateName = stateName
        self.districts = districts
    }
}

public enum IndiaGeoData: Sendable {
    public static let states: [StateDistricts] = [
        StateDistricts(stateName: "National / Pan-India", districts: [
            "All Disaster Zones (Pan-India)",
            "Northern Himalayan Seismic Belt",
            "Western Ghats Coastal Belt",
            "Eastern Coastal & Cyclone Belt",
            "Indo-Gangetic Basin",
            "North-Eastern Frontier"
        ]),
        StateDistricts(stateName: "Andhra Pradesh", districts: [
            "Alluri Sitharama Raju", "Anakapalli", "Ananthapuramu", "Annamayya", "Bapatla", "Chittoor",
            "Dr. B.R. Ambedkar Konaseema", "East Godavari (Rajahmundry)", "Eluru", "Guntur", "Kakinada",
            "Krishna (Machilipatnam)", "Kurnool", "Nandyal", "NTR (Vijayawada)", "Palnadu", "Parvathipuram Manyam",
            "Prakasam (Ongole)", "Sri Potti Sriramulu Nellore", "Sri Sathya Sai", "Srikakulam", "Tirupati",
            "Visakhapatnam", "Vizianagaram", "West Godavari (Bhimavaram)", "YSR Kadapa", "Entire Andhra Pradesh (All Districts)"
        ]),
        StateDistricts(stateName: "Arunachal Pradesh", districts: [
            "Anjaw", "Changlang", "Dibang Valley", "East Kameng", "East Siang", "Kamle", "Kra Daadi",
            "Kurung Kumey", "Leparada", "Lohit", "Longding", "Lower Dibang Valley", "Lower Siang",
            "Lower Subansiri", "Namsai", "Pakke Kessang", "Papum Pare (Itanagar)", "Shi Yomi", "Siang",
            "Tawang", "Tirap", "Upper Siang", "Upper Subansiri", "West Kameng", "West Siang", "Entire Arunachal Pradesh"
        ]),
        StateDistricts(stateName: "Assam", districts: [
            "Baksa", "Barpeta", "Biswanath", "Bongaigaon", "Cachar (Silchar)", "Charaideo", "Chirang",
            "Darrang", "Dhemaji", "Dhubri", "Dibrugarh", "Dima Hasao", "Goalpara", "Golaghat", "Hailakandi",
            "Hojai", "Jorhat", "Kamrup", "Kamrup Metropolitan (Guwahati)", "Karbi Anglong", "Karimganj",
            "Kokrajhar", "Lakhimpur", "Majuli", "Morigaon", "Nagaon", "Nalbari", "Sivasagar", "Sonitpur (Tezpur)",
            "South Salmara-Mankachar", "Tamulpur", "Tinsukia", "Udalguri", "West Karbi Anglong", "Entire Assam (All Districts)"
        ]),
        StateDistricts(stateName: "Bihar", districts: [
            "Araria", "Arwal", "Aurangabad", "Banka", "Begusarai", "Bhagalpur", "Bhojpur (Ara)", "Buxar",
            "Darbhanga", "East Champaran (Motihari)", "Gaya", "Gopalganj", "Jamui", "Jehanabad", "Kaimur (Bhabua)",
            "Katihar", "Khagaria", "Kishanganj", "Lakhisarai", "Madhepura", "Madhubani", "Munger", "Muzaffarpur",
            "Nalanda (Bihar Sharif)", "Nawada", "Patna", "Purnia", "Rohtas (Sasaram)", "Saharsa", "Samastipur",
            "Saran (Chhapra)", "Sheikhpura", "Sheohar", "Sitamarhi", "Siwan", "Supaul", "Vaishali (Hajipur)",
            "West Champaran (Bettiah)", "Entire Bihar (All Districts)"
        ]),
        StateDistricts(stateName: "Chhattisgarh", districts: [
            "Balod", "Baloda Bazar", "Balrampur", "Bastar (Jagdalpur)", "Bemetara", "Bijapur", "Bilaspur",
            "Dantewada (South Bastar)", "Dhamtari", "Durg", "Gariaband", "Gaurela-Pendra-Marwahi", "Janjgir-Champa",
            "Jashpur", "Kabirdham (Kawardha)", "Kanker (North Bastar)", "Khairagarh-Chhuikhadan-Gandai", "Kondagaon",
            "Korba", "Koriya", "Mahasamund", "Manendragarh-Chirmiri-Bharatpur", "Mohla-Manpur-Ambagarh Chowki",
            "Mungeli", "Narayanpur", "Raigarh", "Raipur", "Rajnandgaon", "Sarangarh-Bilaigarh", "Sakti", "Sukma",
            "Surajpur", "Surguja (Ambikapur)", "Entire Chhattisgarh"
        ]),
        StateDistricts(stateName: "Goa", districts: [
            "North Goa (Panaji)", "South Goa (Margao)", "Entire Goa"
        ]),
        StateDistricts(stateName: "Gujarat", districts: [
            "Ahmedabad", "Amreli", "Anand", "Aravalli", "Banaskantha (Palanpur)", "Bharuch", "Bhavnagar",
            "Botad", "Chhota Udaipur", "Dahod", "Dang (Ahwa)", "Devbhumi Dwarka", "Gandhinagar", "Gir Somnath (Veraval)",
            "Jamnagar", "Junagadh", "Kheda (Nadiad)", "Kutch (Bhuj)", "Mahisagar (Lunawada)", "Mehsana", "Morbi",
            "Narmada (Rajpipla)", "Navsari", "Panchmahal (Godhra)", "Patan", "Porbandar", "Rajkot", "Sabarkantha (Himmatnagar)",
            "Surat", "Surendranagar", "Tapi (Vyara)", "Vadodara", "Valsad", "Entire Gujarat (All Districts)"
        ]),
        StateDistricts(stateName: "Haryana", districts: [
            "Ambala", "Bhiwani", "Charkhi Dadri", "Faridabad", "Fatehabad", "Gurugram", "Hisar",
            "Jhajjar", "Jind", "Kaithal", "Karnal", "Kurukshetra", "Mahendragarh (Narnaul)", "Nuh",
            "Palwal", "Panchkula", "Panipat", "Rewari", "Rohtak", "Sirsa", "Sonipat", "Yamunanagar",
            "Entire Haryana"
        ]),
        StateDistricts(stateName: "Himachal Pradesh", districts: [
            "Bilaspur", "Chamba", "Hamirpur", "Kangra (Dharamshala)", "Kinnaur (Reckong Peo)", "Kullu",
            "Lahaul and Spiti (Keylong)", "Mandi", "Shimla", "Sirmaur (Nahan)", "Solan", "Una", "Entire Himachal Pradesh"
        ]),
        StateDistricts(stateName: "Jharkhand", districts: [
            "Bokaro", "Chatra", "Deoghar", "Dhanbad", "Dumka", "East Singhbhum (Jamshedpur)", "Garhwa",
            "Giridih", "Godda", "Gumla", "Hazaribagh", "Jamtara", "Khunti", "Koderma", "Latehar",
            "Lohardaga", "Pakur", "Palamu (Daltonganj)", "Ramgarh", "Ranchi", "Sahebganj", "Saraikela Kharsawan",
            "Simdega", "West Singhbhum (Chaibasa)", "Entire Jharkhand"
        ]),
        StateDistricts(stateName: "Karnataka", districts: [
            "Bagalkote", "Ballari", "Belagavi", "Bengaluru Rural", "Bengaluru Urban", "Bidar", "Chamarajanagara",
            "Chikkaballapura", "Chikkamagaluru", "Chitradurga", "Dakshina Kannada (Mangaluru)", "Davanagere",
            "Dharwad (Hubballi)", "Gadag", "Hassan", "Haveri", "Kalaburagi (Gulbarga)", "Kodagu (Madikeri/Coorg)",
            "Kolar", "Koppal", "Mandya", "Mysuru", "Raichur", "Ramanagara", "Shivamogga", "Tumakuru",
            "Udupi", "Uttara Kannada (Karwar)", "Vijayanagara (Hosapete)", "Vijayapura (Bijapur)", "Yadgir", "Entire Karnataka"
        ]),
        StateDistricts(stateName: "Kerala", districts: [
            "Alappuzha", "Ernakulam (Kochi)", "Idukki (Painavu)", "Kannur", "Kasaragod", "Kollam", "Kottayam",
            "Kozhikode (Calicut)", "Malappuram", "Palakkad", "Pathanamthitta", "Thiruvananthapuram",
            "Thrissur", "Wayanad (Kalpetta)", "Entire Kerala (All Districts)"
        ]),
        StateDistricts(stateName: "Madhya Pradesh", districts: [
            "Agar Malwa", "Alirajpur", "Anuppur", "Ashoknagar", "Balaghat", "Barwani", "Betul", "Bhind",
            "Bhopal", "Burhanpur", "Chhatarpur", "Chhindwara", "Damoh", "Datia", "Dewas", "Dhar", "Dindori",
            "Guna", "Gwalior", "Harda", "Hoshangabad (Narmadapuram)", "Indore", "Jabalpur", "Jhabua",
            "Katni", "Khandwa", "Khargone", "Maihar", "Mandla", "Mandsaur", "Morena", "Narsinghpur",
            "Neemuch", "Niwari", "Panna", "Raisen", "Rajgarh", "Ratlam", "Rewa", "Sagar", "Satna",
            "Sehore", "Seoni", "Shahdol", "Shajapur", "Sheopur", "Shivpuri", "Sidhi", "Singrauli",
            "Tikamgarh", "Ujjain", "Umaria", "Vidisha", "Entire Madhya Pradesh"
        ]),
        StateDistricts(stateName: "Maharashtra", districts: [
            "Ahmednagar (Ahilyanagar)", "Akola", "Amravati", "Aurangabad (Chhatrapati Sambhajinagar)", "Beed",
            "Bhandara", "Buldhana", "Chandrapur", "Dhule", "Gadchiroli", "Gondia", "Hingoli", "Jalgaon",
            "Jalna", "Kolhapur", "Latur", "Mumbai City", "Mumbai Suburban", "Nagpur", "Nanded", "Nandurbar",
            "Nashik", "Osmanabad (Dharashiv)", "Palghar", "Parbhani", "Pune", "Raigad (Alibag)", "Ratnagiri",
            "Sangli", "Satara", "Sindhudurg (Oros)", "Solapur", "Thane", "Wardha", "Washim", "Yavatmal",
            "Entire Maharashtra (All Districts)"
        ]),
        StateDistricts(stateName: "Manipur", districts: [
            "Bishnupur", "Chandel", "Churachandpur", "Imphal East", "Imphal West", "Jiribam", "Kakching",
            "Kamjong", "Kangpokpi", "Noney", "Pherzawl", "Senapati", "Tamenglong", "Tengnoupal", "Thoubal", "Ukhrul", "Entire Manipur"
        ]),
        StateDistricts(stateName: "Meghalaya", districts: [
            "East Garo Hills", "East Jaintia Hills", "East Khasi Hills (Shillong)", "Eastern West Khasi Hills",
            "North Garo Hills", "Ri-Bhoi", "South Garo Hills", "South West Garo Hills", "South West Khasi Hills",
            "West Garo Hills (Tura)", "West Jaintia Hills (Jowai)", "West Khasi Hills (Nongstoin)", "Entire Meghalaya"
        ]),
        StateDistricts(stateName: "Mizoram", districts: [
            "Aizawl", "Champhai", "Hnahthial", "Khawzawl", "Kolasib", "Lawngtlai", "Lunglei", "Mamit", "Saitual", "Serchhip", "Siaha", "Entire Mizoram"
        ]),
        StateDistricts(stateName: "Nagaland", districts: [
            "Chumoukedima", "Dimapur", "Kiphire", "Kohima", "Longleng", "Mokokchung", "Mon", "Niuland",
            "Noklak", "Peren", "Phek", "Shamator", "Tseminyu", "Tuensang", "Wokha", "Zunheboto", "Entire Nagaland"
        ]),
        StateDistricts(stateName: "Odisha", districts: [
            "Angul", "Balangir", "Balasore (Baleswar)", "Bargarh", "Bhadrak", "Boudh", "Cuttack", "Deogarh",
            "Dhenkanal", "Gajapati", "Ganjam (Chhatrapur)", "Jagatsinghpur", "Jajpur", "Jharsuguda", "Kalahandi (Bhawanipatna)",
            "Kandhamal (Phulbani)", "Kendrapara", "Kendujhar (Keonjhar)", "Khurda (Bhubaneswar)", "Koraput", "Malkangiri",
            "Mayurbhanj (Baripada)", "Nabarangpur", "Nayagarh", "Nuapada", "Puri", "Rayagada", "Sambalpur",
            "Subarnapur (Sonepur)", "Sundargarh", "Entire Odisha (All Districts)"
        ]),
        StateDistricts(stateName: "Punjab", districts: [
            "Amritsar", "Barnala", "Bathinda", "Faridkot", "Fatehgarh Sahib", "Fazilka", "Ferozepur",
            "Gurdaspur", "Hoshiarpur", "Jalandhar", "Kapurthala", "Ludhiana", "Malerkotla", "Mansa",
            "Moga", "Muktsar", "Pathankot", "Patiala", "Rupnagar (Ropar)", "Sahibzada Ajit Singh Nagar (Mohali)",
            "Sangrur", "Shahid Bhagat Singh Nagar (Nawanshahr)", "Tarn Taran", "Entire Punjab"
        ]),
        StateDistricts(stateName: "Rajasthan", districts: [
            "Ajmer", "Alwar", "Anupgarh", "Balotra", "Banswara", "Baran", "Barmer", "Beawar", "Bharatpur",
            "Bhilwara", "Bikaner", "Bundi", "Chittorgarh", "Churu", "Dausa", "Deeg", "Didwana-Kuchaman",
            "Dholpur", "Dudu", "Dungarpur", "Gangapur City", "Hanumangarh", "Jaipur", "Jaipur Rural",
            "Jaisalmer", "Jalore", "Jhalawar", "Jhunjhunu", "Jodhpur", "Jodhpur Rural", "Karauli",
            "Kekri", "Khairthal-Tijara", "Kota", "Kotputli-Behror", "Nagaur", "Neem Ka Thana", "Pali",
            "Phalodi", "Pratapgarh", "Rajsamand", "Salumbar", "Sanchore", "Sawai Madhopur", "Shahpura",
            "Sikar", "Sirohi", "Sri Ganganagar", "Tonk", "Udaipur", "Entire Rajasthan"
        ]),
        StateDistricts(stateName: "Sikkim", districts: [
            "Gangtok", "Gyalshing (West Sikkim)", "Mangan (North Sikkim)", "Namchi (South Sikkim)", "Pakyong", "Soreng", "Entire Sikkim"
        ]),
        StateDistricts(stateName: "Tamil Nadu", districts: [
            "Ariyalur", "Chengalpattu", "Chennai", "Coimbatore", "Cuddalore", "Dharmapuri", "Dindigul",
            "Erode", "Kallakurichi", "Kancheepuram", "Karur", "Krishnagiri", "Madurai", "Mayiladuthurai",
            "Nagapattinam", "Kanniyakumari (Nagercoil)", "Namakkal", "Nilgiris (Ooty)", "Perambalur",
            "Pudukkottai", "Ramanathapuram", "Ranipet", "Salem", "Sivaganga", "Tenkasi", "Thanjavur",
            "Theni", "Thoothukudi (Tuticorin)", "Tiruchirappalli", "Tirunelveli", "Tirupathur", "Tiruppur",
            "Tiruvallur", "Tiruvannamalai", "Tiruvarur", "Vellore", "Viluppuram", "Virudhunagar", "Entire Tamil Nadu"
        ]),
        StateDistricts(stateName: "Telangana", districts: [
            "Adilabad", "Bhadradri Kothagudem", "Hanamkonda", "Hyderabad", "Jagtial", "Jangaon",
            "Jayashankar Bhupalpally", "Jogulamba Gadwal", "Kamareddy", "Karimnagar", "Khammam",
            "Kumuram Bheem Asifabad", "Mahabubabad", "Mahabubnagar", "Mancherial", "Medak",
            "Medchal-Malkajgiri", "Mulugu", "Nagarkurnool", "Nalgonda", "Narayanpet", "Nirmal",
            "Nizamabad", "Peddapalli", "Rajanna Sircilla", "Ranga Reddy", "Sangareddy", "Siddipet",
            "Suryapet", "Vikarabad", "Wanaparthy", "Warangal", "Yadadri Bhuvanagiri", "Entire Telangana"
        ]),
        StateDistricts(stateName: "Tripura", districts: [
            "Dhalai", "Gomati", "Khowai", "North Tripura", "Sepahijala", "South Tripura", "Unakoti", "West Tripura (Agartala)", "Entire Tripura"
        ]),
        StateDistricts(stateName: "Uttar Pradesh", districts: [
            "Agra", "Aligarh", "Ambedkar Nagar", "Amethi", "Amroha", "Auraiya", "Ayodhya (Faizabad)", "Azamgarh",
            "Baghpat", "Bahraich", "Ballia", "Balrampur", "Banda", "Barabanki", "Bareilly", "Basti", "Bhadohi",
            "Bijnor", "Budaun", "Bulandshahr", "Chandauli", "Chitrakoot", "Deoria", "Etah", "Etawah", "Farrukhabad",
            "Fatehpur", "Firozabad", "Gautam Buddha Nagar (Noida)", "Ghaziabad", "Ghazipur", "Gonda", "Gorakhpur",
            "Hamirpur", "Hapur", "Hardoi", "Hathras", "Jalaun", "Jaunpur", "Jhansi", "Kannauj", "Kanpur Dehat",
            "Kanpur Nagar", "Kasganj", "Kaushambi", "Kheri (Lakhimpur)", "Kushinagar", "Lalitpur", "Lucknow",
            "Maharajganj", "Mahoba", "Mainpuri", "Mathura", "Mau", "Meerut", "Mirzapur", "Moradabad", "Muzaffarnagar",
            "Pilibhit", "Pratapgarh", "Prayagraj (Allahabad)", "Raebareli", "Rampur", "Saharanpur", "Sambhal",
            "Sant Kabir Nagar", "Shahjahanpur", "Shamli", "Shrawasti", "Siddharthnagar", "Sitapur", "Sonbhadra",
            "Sultanpur", "Unnao", "Varanasi", "Entire Uttar Pradesh (All Districts)"
        ]),
        StateDistricts(stateName: "Uttarakhand", districts: [
            "Almora", "Bageshwar", "Chamoli (Gopeshwar)", "Champawat", "Dehradun", "Haridwar",
            "Nainital", "Pauri Garhwal", "Pithoragarh", "Rudraprayag", "Tehri Garhwal", "Udham Singh Nagar",
            "Uttarkashi", "Entire Uttarakhand (All Districts)"
        ]),
        StateDistricts(stateName: "West Bengal", districts: [
            "Alipurduar", "Bankura", "Birbhum", "Cooch Behar", "Dakshin Dinajpur", "Darjeeling", "Hooghly",
            "Howrah", "Jalpaiguri", "Jhargram", "Kalimpong", "Kolkata", "Malda", "Murshidabad", "Nadia",
            "North 24 Parganas", "Paschim Bardhaman", "Paschim Medinipur", "Purba Bardhaman", "Purba Medinipur (Digha)",
            "Purulia", "South 24 Parganas (Sundarbans)", "Uttar Dinajpur", "Entire West Bengal (All Districts)"
        ]),
        StateDistricts(stateName: "Union Territory: Delhi NCR", districts: [
            "Central Delhi", "East Delhi", "New Delhi", "North Delhi", "North East Delhi", "North West Delhi",
            "Shahdara", "South Delhi", "South East Delhi", "South West Delhi", "West Delhi", "Gurugram (NCR)",
            "Faridabad (NCR)", "Noida (NCR)", "Greater Noida (NCR)", "Ghaziabad (NCR)", "Entire National Capital Region"
        ]),
        StateDistricts(stateName: "Union Territory: Jammu & Kashmir", districts: [
            "Anantnag", "Bandipora", "Baramulla", "Budgam", "Doda", "Ganderbal", "Jammu", "Kathua",
            "Kishtwar", "Kulgam", "Kupwara", "Poonch", "Pulwama", "Rajouri", "Ramban", "Reasi",
            "Samba", "Shopian", "Srinagar", "Udhampur", "Entire Jammu and Kashmir"
        ]),
        StateDistricts(stateName: "Union Territory: Ladakh", districts: [
            "Leh", "Kargil", "Entire Ladakh"
        ]),
        StateDistricts(stateName: "Union Territory: Andaman and Nicobar", districts: [
            "Nicobar", "North and Middle Andaman", "South Andaman (Port Blair)", "Entire Andaman and Nicobar Islands"
        ]),
        StateDistricts(stateName: "Union Territory: Chandigarh", districts: [
            "Chandigarh Urban / Tri-City Area"
        ]),
        StateDistricts(stateName: "Union Territory: Dadra & Nagar Haveli and Daman & Diu", districts: [
            "Dadra and Nagar Haveli (Silvassa)", "Daman", "Diu"
        ]),
        StateDistricts(stateName: "Union Territory: Lakshadweep", districts: [
            "Kavaratti", "Agatti", "Minicoy", "Entire Lakshadweep Islands"
        ]),
        StateDistricts(stateName: "Union Territory: Puducherry", districts: [
            "Karaikal", "Mahe", "Puducherry", "Yanam", "Entire Puducherry"
        ])
    ]
}


