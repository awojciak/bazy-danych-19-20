CREATE OR REPLACE VIEW RezerwacjeWszystkie
AS
    SELECT
        w.ID_WYCIECZKI,
        w.NAZWA,
        w.KRAJ,
        w.DATA,
        o.IMIE,
        o.NAZWISKO,
        r.STATUS
    FROM WYCIECZKI w
        JOIN REZERWACJE r ON w.ID_WYCIECZKI = r.ID_WYCIECZKI
        JOIN OSOBY o ON r.ID_OSOBY = o.ID_OSOBY;

CREATE OR REPLACE VIEW RezerwacjePotwierdzone
AS
    SELECT *
    FROM RezerwacjeWszystkie
        WHERE STATUS in  ('P', 'Z');

CREATE OR REPLACE VIEW RezerwacjeWPrzyszlosci
AS
    SELECT *
    FROM RezerwacjeWszystkie
        WHERE DATA > CURRENT_DATE;

CREATE OR REPLACE VIEW WycieczkiMiejsca
AS
    SELECT
        w.ID_WYCIECZKI,
        w.KRAJ,
        w.DATA,
        w.NAZWA,
        w.LICZBA_MIEJSC,
        (
            SELECT w.LICZBA_MIEJSC-COUNT(*)
            FROM REZERWACJE r
                WHERE (r.STATUS <> 'A') AND (r.ID_WYCIECZKI = w.ID_WYCIECZKI)
        ) AS LICZBA_WOLNYCH_MIEJSC
    FROM WYCIECZKI w;

CREATE OR REPLACE VIEW WycieczkiDostepne
AS
    SELECT *
    FROM WycieczkiMiejsca
        WHERE (LICZBA_WOLNYCH_MIEJSC > 0) AND (DATA > CURRENT_DATE);

CREATE OR REPLACE VIEW WycieczkiMiejsca_v2
AS
    SELECT
        w.ID_WYCIECZKI,
        w.KRAJ,
        w.DATA,
        w.NAZWA,
        w.LICZBA_MIEJSC,
        w.LICZBA_WOLNYCH_MIEJSC
    FROM WYCIECZKI w;

CREATE OR REPLACE VIEW WycieczkiDostepne_v2
AS
    SELECT *
    FROM WycieczkiMiejsca_v2
        WHERE (LICZBA_WOLNYCH_MIEJSC > 0) AND (DATA > CURRENT_DATE);