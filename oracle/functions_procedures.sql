-- typy

CREATE OR REPLACE TYPE REZERWACJA AS OBJECT
(
 ID_WYCIECZKI INT
, NAZWA VARCHAR2(100)
, KRAJ VARCHAR2(50)
, DATA DATE
, IMIE VARCHAR2(50)
, NAZWISKO VARCHAR2(50)
, STATUS CHAR(1)
);

CREATE OR REPLACE TYPE WYCIECZKA AS OBJECT
(
 ID_WYCIECZKI INT
, NAZWA VARCHAR2(100)
, KRAJ VARCHAR2(50)
, DATA DATE
, LICZBA_MIEJSC INT
, LICZBA_WOLNYCH_MIEJSC INT
);

CREATE OR REPLACE TYPE TABELA_REZERWACJi AS TABLE OF REZERWACJA;

CREATE OR REPLACE TYPE TABELA_WYCIECZEK AS TABLE OF WYCIECZKA;

-- zwracające tabele

CREATE OR REPLACE FUNCTION UczestnicyWycieczki(id_danej_wycieczki INT)
    RETURN TABELA_REZERWACJi
AS
    ilosc INT;
    wynik TABELA_REZERWACJi;
    BEGIN
        SELECT COUNT(*)
        INTO ilosc
        FROM WYCIECZKI
            WHERE ID_WYCIECZKI = id_danej_wycieczki;

        IF ilosc = 0 THEN
            RAISE_APPLICATION_ERROR(-20999, 'Wycieczka o danym id nie istnieje w bazie.');
        END IF;

        SELECT REZERWACJA(ID_WYCIECZKI, NAZWA, KRAJ, DATA, IMIE, NAZWISKO, STATUS)
        BULK COLLECT
        INTO wynik
        FROM REZERWACJEWSZYSTKIE
            WHERE (ID_WYCIECZKI = id_danej_wycieczki) AND (STATUS <> 'A');

        RETURN wynik;
    END;

CREATE OR REPLACE FUNCTION RezerwacjeOsoby(id_danej_osoby INT)
    RETURN TABELA_REZERWACJi
AS
    ilosc INT;
    wynik TABELA_REZERWACJi;
    BEGIN
        SELECT COUNT(*)
        INTO ilosc
        FROM OSOBY
            WHERE ID_OSOBY = id_danej_osoby;

        IF ilosc = 0 THEN
            RAISE_APPLICATION_ERROR(-20999, 'Osoba o danym id nie istnieje w bazie');
        END IF;

        SELECT REZERWACJA(
           w.ID_WYCIECZKI,
           w.NAZWA,
           w.KRAJ,
           w.DATA,
           o.IMIE,
           o.NAZWISKO,
           r.STATUS
        )
        BULK COLLECT
        INTO wynik
        FROM WYCIECZKI w
            JOIN REZERWACJE r ON w.ID_WYCIECZKI = r.ID_WYCIECZKI
            JOIN OSOBY o ON r.ID_OSOBY = o.ID_OSOBY
            WHERE o.ID_OSOBY = id_danej_osoby;

        RETURN wynik;
    END;

CREATE OR REPLACE FUNCTION DostepneWycieczki
(
    kraj_docelowy WYCIECZKI.KRAJ%TYPE,
    data_od DATE,
    data_do DATE
)
    RETURN TABELA_WYCIECZEK
AS
    wynik TABELA_WYCIECZEK;
    BEGIN
        IF data_od > data_do THEN
            RAISE_APPLICATION_ERROR(-20999, 'Nieprawidłowy zakres dat.');
        END IF;

        SELECT WYCIECZKA(ID_WYCIECZKI, NAZWA, KRAJ, DATA, LICZBA_MIEJSC, LICZBA_WOLNYCH_MIEJSC)
        BULK COLLECT
        INTO wynik
        FROM WYCIECZKIDOSTEPNE
            WHERE (KRAJ = kraj_docelowy) AND (DATA BETWEEN data_od AND data_do);

        RETURN wynik;
    END;

-- modyfikujące

CREATE OR REPLACE PROCEDURE DodajRezerwacje
(
    id_wycieczki_do_rezerwacji INT,
    id_osoby_rezerwujacej INT
)
AS
    data_wycieczki DATE;
    ilosc_osob INT;
    ilosc_dostepnych INT;
    id_nowej INT;
    ilosc_rezerwacji INT;
    BEGIN
        SELECT DATA
        INTO data_wycieczki
        FROM WYCIECZKI
            WHERE ID_WYCIECZKI = id_wycieczki_do_rezerwacji;

        IF data_wycieczki IS NULL THEN
            RAISE_APPLICATION_ERROR(-20999, 'Wycieczka od danym id nie istnieje w bazie');
        END IF;

        IF data_wycieczki < CURRENT_DATE THEN
            RAISE_APPLICATION_ERROR(-20999, 'Wycieczka już się odbyła');
        END IF;

        SELECT COUNT(*)
        INTO ilosc_osob
        FROM OSOBY
            WHERE ID_OSOBY = id_osoby_rezerwujacej;

        IF ilosc_osob = 0 THEN
            RAISE_APPLICATION_ERROR(-20999, 'Osoba o danym id nie istnieje w bazie');
        END IF;

        SELECT COUNT(*)
        INTO ilosc_dostepnych
        FROM WYCIECZKIDOSTEPNE
            WHERE ID_WYCIECZKI = id_wycieczki_do_rezerwacji;

        IF ilosc_dostepnych = 0 THEN
            RAISE_APPLICATION_ERROR(-20999, 'Brak wolnych miejsc');
        END IF;

        SELECT COUNT(*)
        INTO ilosc_rezerwacji
        FROM REZERWACJE
            WHERE (ID_OSOBY = id_osoby_rezerwujacej) AND (ID_WYCIECZKI = id_wycieczki_do_rezerwacji);

        IF ilosc_rezerwacji <> 0 THEN
            RAISE_APPLICATION_ERROR(-20999, 'Rezerwacja danej wycieczki przez daną osobę już istnieje w bazie');
        END IF;

        INSERT INTO REZERWACJE(ID_WYCIECZKI, ID_OSOBY, STATUS)
        VALUES (id_wycieczki_do_rezerwacji, id_osoby_rezerwujacej, 'N')
        RETURNING NR_REZERWACJI INTO id_nowej;

        INSERT INTO REZERWACJE_LOG(ID_REZERWACJI, DATA, STATUS)
        VALUES (id_nowej, CURRENT_DATE, 'N');

        COMMIT;
    END;

CREATE OR REPLACE PROCEDURE ZmienStatusRezerwacji
(
    nr_danej_rezerwacji INT,
    nowy_status REZERWACJE.STATUS%TYPE
)
AS
    wolne_miejsca INT;
    id_danej_wycieczki INT;
    aktualny_status CHAR(1);
    BEGIN
        SELECT STATUS, ID_WYCIECZKI
        INTO aktualny_status, id_danej_wycieczki
        FROM REZERWACJE
            WHERE NR_REZERWACJI = nr_danej_rezerwacji;

        IF aktualny_status IS NULL THEN
            RAISE_APPLICATION_ERROR(-20999, 'Rezerwacja o danym numerze nie istnieje w bazie');
        END IF;

        SELECT LICZBA_WOLNYCH_MIEJSC
        INTO wolne_miejsca
        FROM WYCIECZKIMIEJSCA
            WHERE ID_WYCIECZKI = id_danej_wycieczki;

        IF (wolne_miejsca = 0) AND (aktualny_status = 'A') THEN
            RAISE_APPLICATION_ERROR(-20999, 'Brak wolnych miejsc; nie można cofnąć anulowanej rezerwacji');
        END IF;

        IF (nowy_status = 'N') THEN
            RAISE_APPLICATION_ERROR(-20999, 'Nie można zmienić statusu rezerwacji już znajdującej się w bazie na nową');
        END IF;

        IF (nowy_status = 'P') AND (aktualny_status = 'Z') THEN
            RAISE_APPLICATION_ERROR(-20999, 'Nie można zmienić statusu zapłaconej rezerwacji na inny poza anulowaną');
        END IF;

        UPDATE REZERWACJE
            SET STATUS = nowy_status
                WHERE NR_REZERWACJI = nr_danej_rezerwacji;

        INSERT INTO REZERWACJE_LOG(ID_REZERWACJI, DATA, STATUS)
        VALUES (nr_danej_rezerwacji, CURRENT_DATE, nowy_status);
        COMMIT;
    END;

CREATE OR REPLACE PROCEDURE ZmienLiczbeMiejsc
(
    id_danej_wycieczki INT,
    nowa_liczba_miejsc INT
)
AS
    ilosc_zarezerwowanych INT;
    ilosc_wycieczek INT;
    BEGIN
        IF nowa_liczba_miejsc < 0 THEN
            RAISE_APPLICATION_ERROR(-20999, 'Nieprawidłowa nowa liczba miejsc');
        END IF;

        SELECT COUNT(*)
        INTO ilosc_wycieczek
        FROM WYCIECZKI
            WHERE ID_WYCIECZKI = id_danej_wycieczki;

        IF ilosc_wycieczek = 0 THEN
            RAISE_APPLICATION_ERROR(-20999, 'Wycieczka o danym id nie istnieje w bazie');
        END IF;

        SELECT LICZBA_MIEJSC - LICZBA_WOLNYCH_MIEJSC
        INTO ilosc_zarezerwowanych
        FROM WYCIECZKIMIEJSCA
            WHERE ID_WYCIECZKI = id_danej_wycieczki;

        IF ilosc_zarezerwowanych > nowa_liczba_miejsc THEN
            RAISE_APPLICATION_ERROR(-20999, 'Nie można zmienić liczmy miejsc; więcej zostało już zarezerwowanych');
        END IF;

        UPDATE WYCIECZKI
            SET LICZBA_MIEJSC = nowa_liczba_miejsc
                WHERE ID_WYCIECZKI = id_danej_wycieczki;

        COMMIT;
    END;

--

CREATE OR REPLACE FUNCTION DostepneWycieczki_v2
(
    kraj_docelowy WYCIECZKI.KRAJ%TYPE,
    data_od DATE,
    data_do DATE
)
    RETURN TABELA_WYCIECZEK
AS
    wynik TABELA_WYCIECZEK;
    BEGIN
        IF data_od > data_do THEN
            RAISE_APPLICATION_ERROR(-20999, 'Nieprawidłowy zakres dat.');
        END IF;

        SELECT WYCIECZKA(ID_WYCIECZKI, NAZWA, KRAJ, DATA, LICZBA_MIEJSC, LICZBA_WOLNYCH_MIEJSC)
        BULK COLLECT
        INTO wynik
        FROM WYCIECZKIDOSTEPNE_V2
            WHERE (KRAJ = kraj_docelowy) AND (DATA BETWEEN data_od AND data_do);

        RETURN wynik;
    END;

CREATE OR REPLACE PROCEDURE DodajRezerwacje_v2
(
    id_wycieczki_do_rezerwacji INT,
    id_osoby_rezerwujacej INT
)
AS
    data_wycieczki DATE;
    ilosc_osob INT;
    ilosc_dostepnych INT;
    id_nowej INT;
    ilosc_rezerwacji INT;
    BEGIN
        SELECT DATA
        INTO data_wycieczki
        FROM WYCIECZKI
            WHERE ID_WYCIECZKI = id_wycieczki_do_rezerwacji;

        IF data_wycieczki IS NULL THEN
            RAISE_APPLICATION_ERROR(-20999, 'Wycieczka od danym id nie istnieje w bazie');
        END IF;

        IF data_wycieczki < CURRENT_DATE THEN
            RAISE_APPLICATION_ERROR(-20999, 'Wycieczka już się odbyła');
        END IF;

        SELECT COUNT(*)
        INTO ilosc_osob
        FROM OSOBY
            WHERE ID_OSOBY = id_osoby_rezerwujacej;

        IF ilosc_osob = 0 THEN
            RAISE_APPLICATION_ERROR(-20999, 'Osoba o danym id nie istnieje w bazie');
        END IF;

        SELECT COUNT(*)
        INTO ilosc_dostepnych
        FROM WYCIECZKIDOSTEPNE_V2
            WHERE ID_WYCIECZKI = id_wycieczki_do_rezerwacji;

        IF ilosc_dostepnych = 0 THEN
            RAISE_APPLICATION_ERROR(-20999, 'Brak wolnych miejsc');
        END IF;

        SELECT COUNT(*)
        INTO ilosc_rezerwacji
        FROM REZERWACJE
            WHERE (ID_OSOBY = id_osoby_rezerwujacej) AND (ID_WYCIECZKI = id_wycieczki_do_rezerwacji);

        IF ilosc_rezerwacji <> 0 THEN
            RAISE_APPLICATION_ERROR(-20999, 'Rezerwacja danej wycieczki przez daną osobę już istnieje w bazie');
        END IF;

        INSERT INTO REZERWACJE(ID_WYCIECZKI, ID_OSOBY, STATUS)
        VALUES (id_wycieczki_do_rezerwacji, id_osoby_rezerwujacej, 'N')
        RETURNING NR_REZERWACJI INTO id_nowej;

        INSERT INTO REZERWACJE_LOG(ID_REZERWACJI, DATA, STATUS)
        VALUES (id_nowej, CURRENT_DATE, 'N');

        UPDATE WYCIECZKI
            SET LICZBA_WOLNYCH_MIEJSC = LICZBA_WOLNYCH_MIEJSC - 1
                WHERE ID_WYCIECZKI = id_wycieczki_do_rezerwacji;

        COMMIT;
    END;

CREATE OR REPLACE PROCEDURE ZmienStatusRezerwacji_v2
(
    nr_danej_rezerwacji INT,
    nowy_status REZERWACJE.STATUS%TYPE
)
AS
    wolne_miejsca INT;
    id_danej_wycieczki INT;
    aktualny_status CHAR(1);
    BEGIN
        SELECT STATUS, ID_WYCIECZKI
        INTO aktualny_status, id_danej_wycieczki
        FROM REZERWACJE
            WHERE NR_REZERWACJI = nr_danej_rezerwacji;

        IF aktualny_status IS NULL THEN
            RAISE_APPLICATION_ERROR(-20999, 'Rezerwacja o danym numerze nie istnieje w bazie');
        END IF;

        SELECT LICZBA_WOLNYCH_MIEJSC
        INTO wolne_miejsca
        FROM WYCIECZKIMIEJSCA_V2
            WHERE ID_WYCIECZKI = id_danej_wycieczki;

        IF (wolne_miejsca = 0) AND (aktualny_status = 'A') THEN
            RAISE_APPLICATION_ERROR(-20999, 'Brak wolnych miejsc; nie można cofnąć anulowanej rezerwacji');
        END IF;

        IF (nowy_status = 'N') THEN
            RAISE_APPLICATION_ERROR(-20999, 'Nie można zmienić statusu rezerwacji już znajdującej się w bazie na nową');
        END IF;

        IF (nowy_status = 'P') AND (aktualny_status = 'Z') THEN
            RAISE_APPLICATION_ERROR(-20999, 'Nie można zmienić statusu zapłaconej rezerwacji na inny poza anulowaną');
        END IF;

        UPDATE REZERWACJE
            SET STATUS = nowy_status
                WHERE NR_REZERWACJI = nr_danej_rezerwacji;

        INSERT INTO REZERWACJE_LOG(ID_REZERWACJI, DATA, STATUS)
        VALUES (nr_danej_rezerwacji, CURRENT_DATE, nowy_status);

        IF nowy_status = 'A' THEN
            UPDATE WYCIECZKI
                SET LICZBA_WOLNYCH_MIEJSC = LICZBA_WOLNYCH_MIEJSC + 1
                    WHERE ID_WYCIECZKI = id_danej_wycieczki;
        END IF;

        COMMIT;
    END;

CREATE OR REPLACE PROCEDURE ZmienLiczbeMiejsc_v2
(
    id_danej_wycieczki INT,
    nowa_liczba_miejsc INT
)
AS
    ilosc_zarezerwowanych INT;
    ilosc_wycieczek INT;
    BEGIN
        IF nowa_liczba_miejsc < 0 THEN
            RAISE_APPLICATION_ERROR(-20999, 'Nieprawidłowa nowa liczba miejsc');
        END IF;

        SELECT COUNT(*)
        INTO ilosc_wycieczek
        FROM WYCIECZKI
            WHERE ID_WYCIECZKI = id_danej_wycieczki;

        IF ilosc_wycieczek = 0 THEN
            RAISE_APPLICATION_ERROR(-20999, 'Wycieczka o danym id nie istnieje w bazie');
        END IF;

        SELECT LICZBA_MIEJSC - LICZBA_WOLNYCH_MIEJSC
        INTO ilosc_zarezerwowanych
        FROM WYCIECZKIMIEJSCA_V2
            WHERE ID_WYCIECZKI = id_danej_wycieczki;

        IF ilosc_zarezerwowanych > nowa_liczba_miejsc THEN
            RAISE_APPLICATION_ERROR(-20999, 'Nie można zmienić liczmy miejsc; więcej zostało już zarezerwowanych');
        END IF;

        UPDATE WYCIECZKI
            SET
                LICZBA_WOLNYCH_MIEJSC = LICZBA_WOLNYCH_MIEJSC + nowa_liczba_miejsc - LICZBA_MIEJSC,
                LICZBA_MIEJSC = nowa_liczba_miejsc
                WHERE ID_WYCIECZKI = id_danej_wycieczki;

        COMMIT;
    END;

--

CREATE OR REPLACE PROCEDURE DodajRezerwacje_v3
(
    id_wycieczki_do_rezerwacji INT,
    id_osoby_rezerwujacej INT
)
AS
    data_wycieczki DATE;
    ilosc_osob INT;
    ilosc_dostepnych INT;
    ilosc_rezerwacji INT;
    BEGIN
        SELECT DATA
        INTO data_wycieczki
        FROM WYCIECZKI
            WHERE ID_WYCIECZKI = id_wycieczki_do_rezerwacji;

        IF data_wycieczki IS NULL THEN
            RAISE_APPLICATION_ERROR(-20999, 'Wycieczka od danym id nie istnieje w bazie');
        END IF;

        IF data_wycieczki < CURRENT_DATE THEN
            RAISE_APPLICATION_ERROR(-20999, 'Wycieczka już się odbyła');
        END IF;

        SELECT COUNT(*)
        INTO ilosc_osob
        FROM OSOBY
            WHERE ID_OSOBY = id_osoby_rezerwujacej;

        IF ilosc_osob = 0 THEN
            RAISE_APPLICATION_ERROR(-20999, 'Osoba o danym id nie istnieje w bazie');
        END IF;

        SELECT COUNT(*)
        INTO ilosc_dostepnych
        FROM WYCIECZKIDOSTEPNE_V2
            WHERE ID_WYCIECZKI = id_wycieczki_do_rezerwacji;

        IF ilosc_dostepnych = 0 THEN
            RAISE_APPLICATION_ERROR(-20999, 'Brak wolnych miejsc');
        END IF;

        SELECT COUNT(*)
        INTO ilosc_rezerwacji
        FROM REZERWACJE
            WHERE (ID_OSOBY = id_osoby_rezerwujacej) AND (ID_WYCIECZKI = id_wycieczki_do_rezerwacji);

        IF ilosc_rezerwacji <> 0 THEN
            RAISE_APPLICATION_ERROR(-20999, 'Rezerwacja danej wycieczki przez daną osobę już istnieje w bazie');
        END IF;

        INSERT INTO REZERWACJE(ID_WYCIECZKI, ID_OSOBY, STATUS)
        VALUES (id_wycieczki_do_rezerwacji, id_osoby_rezerwujacej, 'N');

        UPDATE WYCIECZKI
            SET LICZBA_WOLNYCH_MIEJSC = LICZBA_WOLNYCH_MIEJSC - 1
                WHERE ID_WYCIECZKI = id_wycieczki_do_rezerwacji;

        COMMIT;
    END;

CREATE OR REPLACE PROCEDURE ZmienStatusRezerwacji_v3
(
    nr_danej_rezerwacji INT,
    nowy_status REZERWACJE.STATUS%TYPE
)
AS
    wolne_miejsca INT;
    id_danej_wycieczki INT;
    aktualny_status CHAR(1);
    BEGIN
        SELECT STATUS, ID_WYCIECZKI
        INTO aktualny_status, id_danej_wycieczki
        FROM REZERWACJE
            WHERE NR_REZERWACJI = nr_danej_rezerwacji;

        IF aktualny_status IS NULL THEN
            RAISE_APPLICATION_ERROR(-20999, 'Rezerwacja o danym numerze nie istnieje w bazie');
        END IF;

        SELECT LICZBA_WOLNYCH_MIEJSC
        INTO wolne_miejsca
        FROM WYCIECZKIMIEJSCA_V2
            WHERE ID_WYCIECZKI = id_danej_wycieczki;

        IF (wolne_miejsca = 0) AND (aktualny_status = 'A') THEN
            RAISE_APPLICATION_ERROR(-20999, 'Brak wolnych miejsc; nie można cofnąć anulowanej rezerwacji');
        END IF;

        IF (nowy_status = 'N') THEN
            RAISE_APPLICATION_ERROR(-20999, 'Nie można zmienić statusu rezerwacji już znajdującej się w bazie na nową');
        END IF;

        IF (nowy_status = 'P') AND (aktualny_status = 'Z') THEN
            RAISE_APPLICATION_ERROR(-20999, 'Nie można zmienić statusu zapłaconej rezerwacji na inny poza anulowaną');
        END IF;

        UPDATE REZERWACJE
            SET STATUS = nowy_status
                WHERE NR_REZERWACJI = nr_danej_rezerwacji;

        IF nowy_status = 'A' THEN
            UPDATE WYCIECZKI
                SET LICZBA_WOLNYCH_MIEJSC = LICZBA_WOLNYCH_MIEJSC + 1
                    WHERE ID_WYCIECZKI = id_danej_wycieczki;
        END IF;

        COMMIT;
    END;

--

CREATE OR REPLACE PROCEDURE DodajRezerwacje_v4
(
    id_wycieczki_do_rezerwacji INT,
    id_osoby_rezerwujacej INT
)
AS
    data_wycieczki DATE;
    ilosc_osob INT;
    ilosc_dostepnych INT;
    ilosc_rezerwacji INT;
    BEGIN
        SELECT DATA
        INTO data_wycieczki
        FROM WYCIECZKI
            WHERE ID_WYCIECZKI = id_wycieczki_do_rezerwacji;

        IF data_wycieczki IS NULL THEN
            RAISE_APPLICATION_ERROR(-20999, 'Wycieczka od danym id nie istnieje w bazie');
        END IF;

        IF data_wycieczki < CURRENT_DATE THEN
            RAISE_APPLICATION_ERROR(-20999, 'Wycieczka już się odbyła');
        END IF;

        SELECT COUNT(*)
        INTO ilosc_osob
        FROM OSOBY
            WHERE ID_OSOBY = id_osoby_rezerwujacej;

        IF ilosc_osob = 0 THEN
            RAISE_APPLICATION_ERROR(-20999, 'Osoba o danym id nie istnieje w bazie');
        END IF;

        SELECT COUNT(*)
        INTO ilosc_dostepnych
        FROM WYCIECZKIDOSTEPNE_V2
            WHERE ID_WYCIECZKI = id_wycieczki_do_rezerwacji;

        IF ilosc_dostepnych = 0 THEN
            RAISE_APPLICATION_ERROR(-20999, 'Brak wolnych miejsc');
        END IF;

        SELECT COUNT(*)
        INTO ilosc_rezerwacji
        FROM REZERWACJE
            WHERE (ID_OSOBY = id_osoby_rezerwujacej) AND (ID_WYCIECZKI = id_wycieczki_do_rezerwacji);

        IF ilosc_rezerwacji <> 0 THEN
            RAISE_APPLICATION_ERROR(-20999, 'Rezerwacja danej wycieczki przez daną osobę już istnieje w bazie');
        END IF;

        INSERT INTO REZERWACJE(ID_WYCIECZKI, ID_OSOBY, STATUS)
        VALUES (id_wycieczki_do_rezerwacji, id_osoby_rezerwujacej, 'N');

        COMMIT;
    END;

CREATE OR REPLACE PROCEDURE ZmienStatusRezerwacji_v4
(
    nr_danej_rezerwacji INT,
    nowy_status REZERWACJE.STATUS%TYPE
)
AS
    wolne_miejsca INT;
    id_danej_wycieczki INT;
    aktualny_status CHAR(1);
    BEGIN
        SELECT STATUS, ID_WYCIECZKI
        INTO aktualny_status, id_danej_wycieczki
        FROM REZERWACJE
            WHERE NR_REZERWACJI = nr_danej_rezerwacji;

        IF aktualny_status IS NULL THEN
            RAISE_APPLICATION_ERROR(-20999, 'Rezerwacja o danym numerze nie istnieje w bazie');
        END IF;

        SELECT LICZBA_WOLNYCH_MIEJSC
        INTO wolne_miejsca
        FROM WYCIECZKIMIEJSCA_V2
            WHERE ID_WYCIECZKI = id_danej_wycieczki;

        IF (wolne_miejsca = 0) AND (aktualny_status = 'A') THEN
            RAISE_APPLICATION_ERROR(-20999, 'Brak wolnych miejsc; nie można cofnąć anulowanej rezerwacji');
        END IF;

        IF (nowy_status = 'N') THEN
            RAISE_APPLICATION_ERROR(-20999, 'Nie można zmienić statusu rezerwacji już znajdującej się w bazie na nową');
        END IF;

        IF (nowy_status = 'P') AND (aktualny_status = 'Z') THEN
            RAISE_APPLICATION_ERROR(-20999, 'Nie można zmienić statusu zapłaconej rezerwacji na inny poza anulowaną');
        END IF;

        UPDATE REZERWACJE
            SET STATUS = nowy_status
                WHERE NR_REZERWACJI = nr_danej_rezerwacji;

        COMMIT;
    END;

CREATE OR REPLACE PROCEDURE ZmienLiczbeMiejsc_v3
(
    id_danej_wycieczki INT,
    nowa_liczba_miejsc INT
)
AS
    ilosc_zarezerwowanych INT;
    ilosc_wycieczek INT;
    BEGIN
        IF nowa_liczba_miejsc < 0 THEN
            RAISE_APPLICATION_ERROR(-20999, 'Nieprawidłowa nowa liczba miejsc');
        END IF;

        SELECT COUNT(*)
        INTO ilosc_wycieczek
        FROM WYCIECZKI
            WHERE ID_WYCIECZKI = id_danej_wycieczki;

        IF ilosc_wycieczek = 0 THEN
            RAISE_APPLICATION_ERROR(-20999, 'Wycieczka o danym id nie istnieje w bazie');
        END IF;

        SELECT LICZBA_MIEJSC - LICZBA_WOLNYCH_MIEJSC
        INTO ilosc_zarezerwowanych
        FROM WYCIECZKIMIEJSCA_V2
            WHERE ID_WYCIECZKI = id_danej_wycieczki;

        IF ilosc_zarezerwowanych > nowa_liczba_miejsc THEN
            RAISE_APPLICATION_ERROR(-20999, 'Nie można zmienić liczmy miejsc; więcej zostało już zarezerwowanych');
        END IF;

        UPDATE WYCIECZKI
            SET
                LICZBA_MIEJSC = nowa_liczba_miejsc
                WHERE ID_WYCIECZKI = id_danej_wycieczki;

        COMMIT;
    END;