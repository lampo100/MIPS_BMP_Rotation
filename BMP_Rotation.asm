################################################################################################	
#																																	                   #
#	@   Program w MIPS obracaj¹cy w lewo b¹dŸ prawo,  plik BMP w formacie 24 bitowym, o podan¹ wielokrotnoœæ 90 stopni                   #
#	@	Autor: Kacper Kamiñski 																									               #
#	@		       github.com/lampo100																								             #
#	@																																           # 
#     @	Komentarze w tej samej kolumnie co kod mówi¹ za co odpowiada nastêpuj¹cy segment, a komentarze po prawej stronie        #
#	@	instrukcji doprecozywuj¹ w jakim celu jest ona wywo³ywana															       #
###########################################################################################
										
						.data
			
buf:					.space	 4																	# bufor "œmieciowy" do którego czytane s¹ niepotrzebne informacje
offset:					.space	 4																	# miejsce na offset
bfSize:					.space	 4																	# miejsce na rozmiar oryginalnego obrazka
bfSizeOutput:			.space 	 4																	# miejsce na rozmiar nowego obrazka
width:					.space	 4																	# miejsce na szerokoœæ oryginalnego obrazka
height:					.space 	 4																	# miejsce na wysokoœæ oryginalnego obrazka
poczatek:				.space	 4																	# miejsce na adres nowego obrazka
source:					.space    4																	# miejsce na adres oryginalnego obrazka
strona:					.space	4																	# miejsce na decyzjê o stronie w któr¹ obracamy
kat:					.space	4																	# miejsce na decyzjê o jaki k¹t obracamy obrazek
fileInput:				.space	64																	# miejsce na nazwê pliku
#fileInput:				.asciiz 	"C:\\Users\\Kacper\\Desktop\\MIPS\\in.bmp"
fileOutput:				.asciiz 	"C:\\Users\\Kacper\\Desktop\\MIPS\\out.bmp"
msgLoadingFailed:		.asciiz 	"Blad wczytywania pliku\n"
msgWelcome:			.asciiz 	"Program obracajacy plik o n*90 stopni w podanym kierunku\n"
msgGiveSource:		.asciiz	"Podaj pelna sciezke do pliku\n"
msgWhichDirection:	.asciiz	"W ktora strone obrocic obrazek?( 0 w lewo, 1 w prawo)\n"
msgHowMuch:			.asciiz	"O jaka wielokrotnosc 90 stopni obrocic obrazek?( liczba naturalna )\n"
			
						.text


						
main:
		# Program zosta³ uruchomiony. Wyœwietl wiadomoœæ powitaln¹
		li $v0, 4
		la $a0, msgWelcome
		syscall
		
		# Wyœwietl proœbê o podanie œcie¿ki do pliku
		li $v0, 4
		la $a0, msgGiveSource
		syscall
		
		  li $v0, 8        				# procedura wczytujaca string
  		  la $a0, fileInput  			# zaladowanie adresu bufora, gdzie ma byc zapisany tekst
		  li $a1, 64    				# wczytanie rozmiaru bufora
 		  syscall
  		  la $v0, fileInput
makestring:
      		  lb $a3, ($v0)             		 # zaladowanie  znaku
   	          addi $v0, $v0, 1          
      		  bnez $a3,makestring 		 # az znak - \0
      		  beq $a1, $v0, skip       		 # jesli max znakow, nie ma \n
    	          subiu $v0, $v0, 2         
      		  sb $0, ($v0)              		 # zamiana \n na \0
 skip:
		
		# W któr¹ stronê obróciæ obrazek?
		li $v0, 4
		la $a0, msgWhichDirection
		syscall
		
		#Wczytujemy decyzjê
		li $v0, 5
		syscall
		sw	$v0, strona
		
		#O ile stopni obróciæ obrazek?
		li $v0, 4
		la $a0, msgHowMuch
		syscall
		
		#Wczytujemy decyzje
		li $v0, 5
		syscall
		sw $v0, kat

readFile:

	##########################################################################
	# Zawartosc rejestrow:
	##########################################################################
	# $t1 --> deskryptor pliku
	# $t6 --> rejestr do obliczeñ
	# $s0 --> rozmiar pliku
	# $s1 --> adres zaalokowanej pamieci na oryginalny obrazek
	# $s2 --> width
	# $s3 --> height
	# $s4 --> adres zaalokowanej pamieci na nowy obrazek
	# $s7 --> rozmiar nowego obrazka
	##########################################################################

		# otworzenie pliku o nazwie 'in.bmp':
		la $a0, fileInput
		li $a1, 0
		li $a2, 0
		li $v0, 13
		syscall	
	
		# deskryptor pliku do $t1
		move $t1, $v0 		
		
		# je¿eli wczytywanie siê nie powiod³o
		bltz $t1, fileFailed	
	
	##########################################################################
	#									Odczytanie informacji  z FILEHEADER
	##########################################################################
	#
	#			<Pole>		<Rozmiar>	<Opis>
	#			bfType				2			The characters "BM"
	#			bfSize				4			The size of the file in bytes
	#			bfReserved1		2			Unused - must be zero										
	#			bfReserved2		2			Unused - must be zero							
	#			bfOffBits			4			Offset to start of Pixel Data								
	#
	##########################################################################
	
				
		# odczytanie 2 bajtow 'BM':
		move $a0, $t1
		la $a1, buf
		li $a2, 2
		li $v0, 14
		syscall
	
		# odczytanie 4 bajtow okreœlajacych rozmiar pliku
		move $a0, $t1
		la $a1, bfSize
		li $a2, 4
		li $v0, 14
		syscall
	
		# zapisanie rozmiaru w $s0
		lw $s0, bfSize	
	
	
		# alokacja pamieci na oryginalny obrazek o rozmiarze pliku:
		move $a0, $s0
		li $v0, 9
		syscall
		# przekazanie adresu zaalokowanej pamieci na oryginalny obrazek do $s1
		move $s1, $v0		
		sw $s1, source
	
		# przywrocenie deskryptora pliku dla $a0
		move $a0, $t1	
		
		# odczytanie 4 bajtow zarezerwowanych
		la $a1, buf
		li $a2, 4
		li $v0, 14
		syscall
	
		# odczytanie offsetu:
		move $a0, $t1
		la $a1, offset
		li $a2, 4
		li $v0, 14
		syscall
		
		# Zapisanie offsetu do $s5
		lw $s5, offset
		
	###################################################################################
	#										Odczytanie informacji z Image Header
	###################################################################################
	#		<Pole>				<Rozmiar>	<Opis>
	#	
	#		biSize						4			Header Size - Must be at least 40
	#		biWidth					4			Image width in pixels
	#		biHeight					4			Image height in pixels
	#		biPlanes					2			Must be 1
	#		biBitCount					2			Bits per pixel - 1, 4, 8, 16, 24, or 32
	#		biCompression				4			Compression type (0 = uncompressed)
	#		biSizeImage				4			Image Size - may be zero for uncompressed images
	#		biXPelsPerMeter			4			Preferred resolution in pixels per meter
	#		biYPelsPerMeter			4			Preferred resolution in pixels per meter
	#		biClrUsed					4			Number Color Map entries that are actually used
	#		biClrImportant				4			Number of significant colors
	#
	###################################################################################
	
		# odczytanie 4 bajtow rozmiaru nag³ówka:
		move $a0, $t1
		la $a1, buf
		li $a2, 4
		li $v0, 14
		syscall
	
		# odczytanie szerokoœci  obrazka:
		move $a0, $t1
		la $a1, width
		li $a2, 4
		li $v0, 14
		syscall
	
		# zaladowanie szerokoœci do $s2
		lw $s2, width	
	
		# odczytanie wysokosci  obrazka:
		move $a0, $t1
		la $a1, height
		li $a2, 4
		li $v0, 14
		syscall
	
		# zaladowanie height do $s3
		lw $s3, height			
		
		#Wczytujemy k¹t o który obracamy i patrzymy czy nie jest on wielokrotnoœci¹ 180 stopni, jak tak to padding jest ten sam
		lw $t8, kat
		rem $t8, $t8, 2
		beqz $t8, paddingIsTheSame
		
calculateNewImagePadding:

		#Obliczamy ile bajtów paddingu bedzie mia³ nowy obrazek	
		move $t7, $s3	
		rem $t7, $t7, 4
		beq $t7, 0, paddingIs0
		beq $t7, 1, paddingIs1
		beq $t7, 2, paddingIs2
		beq $t7, 3, paddingIs3
		
paddingIs0:

		#Nie ma paddingu, rozmiar nowego pliku to offset + width * height  *  3
		mulu $s7, $s2, $s3
		
		# Szerokoœæ i wysokoœæ s¹ w pikselach, wiêc mno¿ymy jeszcze razy 3(dostaniemy rozmiar tablicy pikseli w bajtach)
		li $t8, 3
		mulu $s7, $s7, $t8
		addu $s7, $s7, $s5
		b allocateForNew
		
paddingIs1:

		# Padding 1 bajt w ka¿dym wierszu nowego obrazka. Rozmiar nowego pliku to offset + width * (height + 1) * 3
		addiu $t7, $s3, 1 
		mulu $s7, $s2, $t7
		
		# Szerokoœæ i wysokoœæ s¹ w pikselach, wiêc mno¿ymy jeszcze razy 3 (dostaniemy rozmiar tablicy pikseli w bajtach)
		li $t8, 3
		mulu $s7, $s7, $t8
		addu $s7, $s7, $s5
		b allocateForNew
		
paddingIs2:

		# Padding 2 bajty w ka¿dym wierszu nowego obrazka. Rozmiar nowego pliku to offset + width * (height + 2) * 3
		addiu $t7, $s3, 2
		mulu $s7, $s2, $t7
		
		# Szerokoœæ i wysokoœæ s¹ w pikselach, wiêc mno¿ymy jeszcze razy 3 (dostaniemy rozmiar tablicy pikseli w bajtach)
		li $t8, 3
		mulu $s7, $s7, $t8
		addu $s7, $s7, $s5
		b allocateForNew
		
paddingIs3:

		# Padding 3 bajty w ka¿dym wierszu nowego obrazka. Rozmiar nowego pliku to offset + width * (height + 3) * 3
		addiu $t7, $s3, 3
		mulu $s7, $s2, $t7
		
		# Szerokoœæ i wysokoœæ s¹ w pikselach, wiêc mno¿ymy jeszcze razy 3(dostaniemy rozmiar tablicy pikseli w bajtach)
		li $t8, 3
		mulu $s7, $s7, $t8
		addu $s7, $s7, $s5
		b allocateForNew	
		
paddingIsTheSame:
		#Przy obrocie o 180 stopni padding jest ten sam
		move $s7, $s0
					
allocateForNew:

		# Wpisanie rozmiaru nowego pliku do bfSizeOutput
		sw $s7, bfSizeOutput
		
		# alokacja pamiêci na nowy plik:
		move $a0, $s7
		li $v0, 9
		syscall	
		
		# przekazanie adresu zaalokowanej pamiêci do $s4
		move $s4, $v0		
		
		# Zapisanie adresu w poczatek
		sw $s4, poczatek
		
		# zamkniecie pliku:
		move $a0, $t1
		li $v0, 16
		syscall
	
writeHeadersToTarget:

		# wczytuje tablice pikseli pod adres zaalokowanej pamieci w $s1
		la $a0, fileInput
		la $a1, 0
		la $a2, 0
		li $v0, 13
		syscall
	
		#deskryptor pliku do $t1
		move $t1, $v0
		
		# Za³adowanie offsetu do $s5
		lw $s5, offset
		
		# wczytanie do pamiêci na nowy obrazek ($s4) wszystkich bajtów obrazka Ÿród³owego, a¿ do tabliby pikseli)
		move $a0, $t1
		la $a1, ($s4)
		la $a2, ($s5)		
		li $v0, 14
		syscall
		
		# zamkniecie pliku
		move $a0, $t1		
		li $v0, 16
		syscall
		
		#Wczytujemy k¹t o który obracamy i patrzymy czy nie jest on wielokrotnoœci¹ 180 stopni, jak tak to nie zmieniamy pól Size, Height i Width
		lw $t8, kat
		rem $t8, $t8, 2
		beqz $t8, loadSourceToMemory

changeSizeHeightAndWidth:
		
		# Przechowujemy adres nowej pamiêci
		move $t7, $s4
		
		# Przechodzimy w pamiêci na nowy plik do bajtów zawieraj¹cych rozmiar pliku
		addiu $s4, $s4, 2
		
		#£adujemy do $s7 nowy rozmiar
		lw $s7, bfSizeOutput
		lw $s0, bfSize
		sb $s7, ($s4)			# £adujemy do pamiêci ostatni bajt rejestru (Zaczynamy w pamiêci od ostatniego bajtu poniewa¿ Little Endian)
		srl $s7, $s7, 8			# Przesuwamy rejest logicznie o 8 miejsca w prawo 
		addiu $s4, $s4, 1		# Przesuwamy adres o 1 bajt
		sb $s7, ($s4)			# £adujemy do pamiêci przedostatni(oryginalnie) bajt rejestru
		srl $s7, $s7, 8			# Przesuwamy rejest logicznie o 8 miejsca w prawo
		addiu $s4, $s4, 1		# Przesuwamy adres o 1 bajt
		sb $s7, ($s4)			# £adujemy do pamiêci 3 od prawej(oryginalnie) bajt rejestru
		srl $s7, $s7, 8			# Przesuwamy rejest logicznie o 8 miejsca w prawo
		addiu $s4, $s4, 1		# Przesuwamy adres o 1 bajt
		sb $s7, ($s4)			# £adujemy do pamiêci pierwszy(oryginalnie) bajt rejestru
		addiu $s4, $s4, 1		# Przesuwamy adres o 1 bajt
		lw $s7, bfSizeOutput
		
		# Przechodzimy w pamiêci na nowy plik do bajtów zawieraj¹cych szerokoœæ  pliku i podmieniamy na wysokoœæ
		addiu $s4, $s4, 12
		lw $s3, height
		sb $s3, ($s4)
		srl $s3, $s3, 8
		addiu $s4, $s4, 1
		sb $s3, ($s4)
		srl $s3, $s3, 8
		addiu $s4, $s4, 1
		sb $s3, ($s4)
		srl $s3, $s3, 8
		addiu $s4, $s4, 1
		sb $s3, ($s4)
		srl $s3, $s3, 8
		addiu $s4, $s4, 1
		lw $s3, height
		
		# Przechodzimy w pamiêci na nowy plik do bajtów zawieraj¹cych wysokoœæ pliku i podmieniamy na szerokoœæ
		lw $s2, width
		sb $s2, ($s4)
		srl $s2, $s2, 8
		addiu $s4, $s4, 1
		sb $s2, ($s4)
		srl $s2, $s2, 8
		addiu $s4, $s4, 1
		sb $s2, ($s4)
		srl $s2, $s2, 8
		addiu $s4, $s4, 1
		sb $s2, ($s4)
		addiu $s4, $s4, 1
		lw $s2, width
		
loadSourceToMemory:
		#£adujemy obrazek Ÿród³owy do pamiêci
		# wczytuje tablice pikseli pod adres zaalokowanej pamieci w $s1
		la $a0, fileInput
		la $a1, 0
		la $a2, 0
		li $v0, 13
		syscall
	
		#deskryptor pliku do $t1
		move $t1, $v0
		
		# Za³adowanie rozmiaru do $s0
		lw $s0, bfSize
		
		# Za³adowanie adresu obrazka Ÿród³owego do $s1
		lw $s1, source
		
		# wczytanie do pamiêci starego obrazka
		move $a0, $t1
		la $a1, ($s1)
		la $a2, ($s0)		
		li $v0, 14
		syscall
		
		# zamkniecie pliku
		move $a0, $t1		
		li $v0, 16
		syscall
rotate:
	##########################################################################
	#                                                                              Zawartosc rejestrow						
	##########################################################################
	# $s0 --> rozmiar starego obrazka
	# $s7 --> rozmiar nowego obrazka
	# $s1 --> adres zaalokowanej pamieci (gdzie wczytany zostal caly plik bmp)
	# $t9 --> adres Ÿród³owego piksela
	# $s4 --> adres zaalokowanej pamieci na nowy obrazek
	# $s2 --> width
	# $s3 --> height
	# $s5 --> offset
	# $t5 --> liczba pikseli w calym pliku (koniec petli)
	# $s6 --> licznik pikseli w nowym wierszu
	# $t3 --> licznik pikseli w starym wierszu
	##########################################################################
	# $t0 --> R piksela
	# $t1 --> G piksela
	# $t2 --> B piksela
	# $t4 --> licznik wstawionych pikseli
	# $t6 --> tymczasowy rejestr do obliczen
	# $t7 --> iloœæ bajtów paddingu w nowym obrazku
	# $t8 --> iloœæ bajtów paddingu w obrazku Ÿród³owym
	##########################################################################
		
		
		lw $s1, source				# £adujemy do $s1 adres obrazka Ÿród³owego
		lw $s0, bfSize				# £adujemy do $s0 rozmiar obrazka Ÿród³owego
		lw $s7, bfSizeOutput		# £adujemy do $s7 rozmiar obrazka docelowego
		mulu $t5, $s2, $s3			# £adujemy do $t5 iloœæ pikseli ( je¿eli wstawimy t¹ wartoœæ to przerywamy pêtlê)
		li $t4, 0						# Zerujemy licznik wstawionych pikseli
		li $s6, 0						# Zerujemy licznik wstawionych pikseli w wierszu
		lw $s5, offset				# £adujemy do $s5 wartoœæ offsetu
		
		#Obliczamy ile bajtów paddingu bedzie mia³ nowy obrazek	
		move $t7, $s3	
		rem $t7, $t7, 4	
		
		#Obliczamy ile bajtów paddingu ma stary obrazek	
		move $t8, $s2
		rem $t8, $t8, 4

howToRotate:
		#W któr¹ stronê i o ile bêdziemy obracaæ obrazek?
		
		lw $t0, strona			# £adujemy decyzjê o stronie
		lw $t1, kat				# £adujemy decyzjê o k¹cie
		remu $t1, $t1, 4		# Sprowadzamy decyjê o k¹cie do 4 podstawowych wartoœci (0, 1, 2, 3), czyli odpowiednio: brak obrotu, o 90 stopni,
								# o 180 stopni, oraz o 270 stopni
		beqz $t0, toTheLeft	# Obracamy w lewo
		beq $t0, 1, toTheRight	# Obracamy w prawo
		
toTheLeft:
		beq $t1, 1, rotate90DegreesLeft
		beq $t1, 2, rotate180Degrees
		beq $t1, 3, rotate90DegreesRight
		beqz $t1, dontRotate
toTheRight:
		beq $t1, 1, rotate90DegreesRight
		beq $t1, 2, rotate180Degrees
		beq $t1, 3, rotate90DegreesLeft
		beqz $t1, dontRotate
################################################################################################
#															ROTACJE
################################################################################################
rotate90DegreesLeft:
		# Obrót o 90 stopni w lewo wyszukuje piksel Ÿród³owy na pozycji (x,y)  x: <1;szerokoœæ> y: <1;wysokoœæ>
		# Wyra¿one jest to wzorem P(x,y) = (Wysokoœæ - y)*Szerokoœæ + x  gdzie Wysokoœæ i Szerokoœæ s¹ to wymiary Ÿród³a
		# (!!) W tym obrocie $s0 jest numerem obecnego wiersza (!!)
		# (!!) W tym obrocie $s7 jest rejestrem do obliczeñ (!!)
		
		# £adujemy do $s4 adres obrazka docelowego
		lw $s4, poczatek
		addu $s4, $s4, $s5				# Przesuwamy adres nowego obrazka do tabeli pikseli
		addu $s1, $s1, $s5				# Przesuwamy adres starego obrazka do tabeli pikseli
		
		li $s0, 1							# £adujemy numer obecnego wierszu(Zaczynamy od 1)
		move $t9, $s1					# Zapamiêtujemy adres pocz¹tkowy w $t9
		
loop90L:
		beq	 $t4, $t5, saveFile			# Je¿eli zapisaliœmy wszystkie piksele, zapisz plik

calculateOldPixel:
		addiu $s6, $s6, 1				# Dodajemy tymczasowo 1 do pikseli w nowym wierszu (y) aby by³a zgodnoœæ ze wzorem
		move $t6, $s3					# £adujemy wysokoœæ do $t6
		subu $t6, $t6, $s6				# Liczymy (Wysokoœæ - y)
		mulu $t6, $t6, $s2				# Liczymy (Wysokoœæ - y) * Szerokoœæ
		addu $t6, $t6, $s0				# Liczymy (Wysokoœæ - y) * Szerokoœæ + x 
		move $s7, $t6
		addiu $s7, $s7, -1
	
		divu $s7, $s7, $s2 				#Obliczamy przez ile paddingów bêdziemy musieli przejœæ
		mulu $s7, $s7, $t8				# Liczba paddingów razy iloœæ bajtów w paddingu
		mulu $t6, $t6, 3				# Ka¿dy piksel ma trzy bajty
		addu $t6, $t6, $s7				# Dodajemy bajty paddingu do bajtów pikseli
		
		addu $s1, $s1, $t6				#Przechodzimy za docelowy piksel
		subiu $s1, $s1, 3				# Odejmujemy 3 bajty (nasz jeden piksel)
		addiu $s6, $s6, -1
getRGB:		

		lbu $t0, ($s1)					#£adujemy R piksela
		addiu $s1, $s1, 1
		lbu $t1, ($s1)					#£adujemy G piksela
		addiu $s1, $s1, 1
		lbu $t2, ($s1)					#£adujemy B piksela

		
		sb $t0, ($s4)					# Zapisujemy R
		addiu $s4, $s4, 1
		sb $t1, ($s4)					# Zapisujemy G
		addiu $s4, $s4, 1
		sb $t2, ($s4)					# Zapisujemy B
		addiu $s4, $s4, 1		
		
		addiu $t4, $t4, 1				# Zwiêkszamy licznik wstawionych pikseli

		addiu $s6, $s6, 1				# Zwiêkszamy licznik wstawionych pikseli w wierszu
		addiu $t3, $t3, 1				# Zwiêkszamy licznik pobranych pikseli
		move $s1, $t9					# Przywracamy pocz¹tkowy adres tabeli pikseli
		beq  $s6, $s3, paddingNew		# Je¿eli doszliœmy do paddingu to go przeskakujemy
		b loop90L	
			
paddingNew:

		addu $s4, $s4, $t7				# Przechodzimy padding
		addiu $s0, $s0, 1				# Zwiêkszamy numer obecnego wiersza
		li $s6, 0							# Zerujemy licznik wstawionych pikseli w wierszu
		b loop90L		
###########################################################################################\

rotate90DegreesRight:
		# Obrót o 90 stopni w lewo wyszukuje piksel Ÿród³owy na pozycji (x,y)  x: <1;szerokoœæ> y: <1;wysokoœæ>
		# Wyra¿one jest to wzorem P(x,y) = Szerokoœæ * y - x + 1  gdzie Wysokoœæ i Szerokoœæ s¹ to wymiary Ÿród³a
		# (!!) W tym obrocie $s0 jest numerem obecnego wiersza (!!)
		# (!!) W tym obrocie $s7 jest rejestrem do obliczeñ (!!)
		
		# £adujemy do $s4 adres obrazka docelowego
		lw $s4, poczatek
		addu $s4, $s4, $s5				# Przesuwamy adres nowego obrazka do tabeli pikseli
		addu $s1, $s1, $s5				# Przesuwamy adres starego obrazka do tabeli pikseli
		
		li $s0, 1							# £adujemy numer obecnego wierszu(Zaczynamy od 1)
		move $t9, $s1					# Zapamiêtujemy adres pocz¹tkowy w $t9
		
loop90R:
		beq	 $t4, $t5, saveFile

calculateOldPixel2:
		addiu $s6, $s6, 1				
		move $t6, $s2					# £adujemy szerokoœæ do $t6
		mulu $t6, $t6, $s6				# Liczymy Szerokoœæ * y
		subu $t6, $t6, $s0				# Liczymy Szerokoœæ * y - x
		addiu $t6, $t6, 1				# Liczymy Szerokoœæ * y - x + 1
		move $s7, $t6					# Kopiujemy tê wartoœæ do tymczasowego bufora
		addiu $s7, $s7, -1
	
		divu $s7, $s7, $s2 				#Obliczamy przez ile paddingów bêdziemy musieli przejœæ
		mulu $s7, $s7, $t8				# Liczba paddingów razy iloœæ bajtów w paddingu
		mulu $t6, $t6, 3				# Ka¿dy piksel ma trzy bajty
		addu $t6, $t6, $s7				# Dodajemy bajty paddingu do bajtów pikseli
		
		addu $s1, $s1, $t6				#Przechodzimy za docelowy piksel
		subiu $s1, $s1, 3				# Odejmujemy 3 bajty (nasz jeden piksel)
		addiu $s6, $s6, -1				
getRGB2:		

		lbu $t0, ($s1)					#£adujemy R piksela
		addiu $s1, $s1, 1
		lbu $t1, ($s1)					#£adujemy G piksela
		addiu $s1, $s1, 1
		lbu $t2, ($s1)					#£adujemy B piksela

		
		sb $t0, ($s4)					# Zapisujemy R
		addiu $s4, $s4, 1
		sb $t1, ($s4)					# Zapisujemy G
		addiu $s4, $s4, 1
		sb $t2, ($s4)					# Zapisujemy B
		addiu $s4, $s4, 1		
		
		addiu $t4, $t4, 1				# Zwiêkszamy licznik wstawionych pikseli

		addiu $s6, $s6, 1				# Zwiêkszamy licznik wstawionych pikseli w wierszu
		addiu $t3, $t3, 1				# Zwiêkszamy licznik pobranych pikseli
		move $s1, $t9					# Przywracamy pocz¹tkowy adres tabeli pikseli
		beq  $s6, $s3, paddingNew2	# Je¿eli doszliœmy do padding, to przechodzimy go
		b loop90R	
			
paddingNew2:

		addu $s4, $s4, $t7				# Przechodzimy padding
		addiu $s0, $s0, 1				# Zwiêkszamy numer obecnego wiersza
		li $s6, 0							# Zerujemy licznik wstawionych pikseli w wierszu
		b loop90R	
		
#############################################################################################				
rotate180Degrees:
		# Obrót o 180 stopni jest to tylko zamienienie ze sob¹ kolejnoœci¹ pikseli w macierzy pikseli

		#Przy obrocie o 180 stopni padding pozostaje ten sam
		move $t7, $t8	

		#Przesuwamy wskaŸnik za obrazek Ÿród³owy
		addu $s1, $s1, $s0
		subu $s1, $s1, $t8			# Przesuwamy o padding (Znajdziemy siê tu¿ za ostatnim pikselem)
		
		# £adujemy do $s4 adres obrazka docelowego
		lw $s4, poczatek
		addu $s4, $s4, $s5
		
		
		
loop180:
		beq	 $t4, $t5, saveFile
		
		addiu $s1, $s1, -1
		lbu $t2, ($s1)					#£adujemy B piksela
		addiu $s1, $s1, -1
		lbu $t1, ($s1)					#£adujemy G piksela
		addiu $s1, $s1, -1
		lbu $t0, ($s1)					#£adujemy R piksela

		
		sb $t0, ($s4)					# Zapisujemy R
		addiu $s4, $s4, 1
		sb $t1, ($s4)					# Zapisujemy G
		addiu $s4, $s4, 1
		sb $t2, ($s4)					# Zapisujemy B
		addiu $s4, $s4, 1		
		
		addiu $t4, $t4, 1				# Zwiêkszamy licznik wstawionych pikseli

		addiu $s6, $s6, 1				# Zwiêkszamy licznik wstawionych pikseli w wierszu
		addiu $t3, $t3, 1				# Zwiêkszamy licznik pobranych pikseli

		beq  $s6, $s2, paddingNew3	# W nowym obrazku doszliœmy do paddingu, przeskocz go
		
checkOldPadding3:

		beq $t3, $s2, paddingOld3		# W starym obrazku doszliœmy do paddingu, przeskocz go
		b loop180
		
paddingNew3:

		addu $s4, $s4, $t7				# Przeskocz padding
		li $s6, 0							#Wyzeruj licznik wstawionych pikseli w wierszu
		b checkOldPadding3		

		
paddingOld3:

		subu $s1, $s1, $t8				# Przeskocz padding
		li $t3, 0							# Wyzeruj licznik pobranych pikseli ze starego wiersza
		b loop180
		
##################################################################################################
dontRotate:		
		#£adujemy obrazek Ÿród³owy do pamiêci w miejscu starego obrazka
		la $a0, fileInput
		la $a1, 0
		la $a2, 0
		li $v0, 13
		syscall
	
		#deskryptor pliku do $t1
		move $t1, $v0
		
		# Za³adowanie rozmiaru do $s0
		lw $s0, bfSize
		
		# Za³adowanie adresu obrazka docelowego do $s4
		lw $s4, poczatek
		
		# wczytanie do pamiêci starego obrazka w miejsce nowego obrazka
		move $a0, $t1
		la $a1, ($s4)
		la $a2, ($s0)		
		li $v0, 14
		syscall
		
		# zamkniecie pliku
		move $a0, $t1		
		li $v0, 16
		syscall
##################################################################################################
#															Koniec algorytmów rotacji
##################################################################################################
saveFile:
		# zapisujemy wynik pracy w pliku "out.bmp"
		la $a0, fileOutput
		li $a1, 1
		li $a2, 0
		li $v0, 13
		syscall
		
		# Kopiujemy deskryptor do $t0
		move $t0, $v0
		
		# Sprawdzamy czy poprawcznie zakoñczono otwieranie pliku
		bltz $t0, fileFailed
		
		# £adujemy rozmiar nowego obrazka do $s0, oraz adres pocz¹tku naszego nowego obrazka w $s4
		lw $s0, bfSizeOutput
		lw $s4, poczatek
		
		# Zapisujemy nowy obrazek do pliku
		move $a0, $t0
		la $a1, ($s4)
		la $a2, ($s0)
		li $v0, 15
		syscall
		
		# Zamykamy obrazek
		move $a0, $t0
		li $v0, 16
		syscall
		
		b exit
fileFailed:

		# Wczytywanie nie powiod³o siê. Wyœwietl wiadomoœæ.
		la $a0, msgLoadingFailed
		li $v0, 4
		syscall
	
exit:	

		# Zamkniêcie programu:
		li $v0, 10
		syscall
