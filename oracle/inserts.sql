-- osoby
INSERT INTO osoby (imie, nazwisko, pesel, kontakt)
VALUES('Adam', 'Kowalski', '87654321', 'tel: 6623');

INSERT INTO osoby (imie, nazwisko, pesel, kontakt)
VALUES('Jan', 'Nowak', '12345678', 'tel: 2312, dzwonić po 18.00');

INSERT INTO osoby (imie, nazwisko, pesel, kontakt)
VALUES('Ewa', 'Woźniak', '12121212', 'tel: 1234');

INSERT INTO osoby (imie, nazwisko, pesel, kontakt)
VALUES('Daniel', 'Duda', '34343434', 'tel: 5678');

INSERT INTO osoby (imie, nazwisko, pesel, kontakt)
VALUES('Paweł', 'Kaczyński', '56565656', 'tel: 9012');

INSERT INTO osoby (imie, nazwisko, pesel, kontakt)
VALUES('Zofia', 'Kukiz', '78787878', 'tel: 3456');

INSERT INTO osoby (imie, nazwisko, pesel, kontakt)
VALUES('Anna', 'Korwini', '90909090', 'tel: 7890');

INSERT INTO osoby (imie, nazwisko, pesel, kontakt)
VALUES('Janusz', 'Pawlacz', '21212121', 'tel: 1488');

INSERT INTO osoby (imie, nazwisko, pesel, kontakt)
VALUES('Sebastian', 'Tusk', '43434343', 'tel: 0911');

INSERT INTO osoby (imie, nazwisko, pesel, kontakt)
VALUES('Marek', 'Wojtyła', '65656565', 'tel: 1410');

-- wycieczki
INSERT INTO wycieczki (nazwa, kraj, data, opis, liczba_miejsc)
VALUES ('Wycieczka do Paryza','Francja',TO_DATE('2016-01-01','YYYY-MM-DD'),'Ciekawa wycieczka ...',3);

INSERT INTO wycieczki (nazwa, kraj, data, opis, liczba_miejsc)
VALUES ('Piękny Kraków','Polska',TO_DATE('2017-02-03','YYYY-MM-DD'),'Najciekawa wycieczka ...',5);

INSERT INTO wycieczki (nazwa, kraj, data, opis, liczba_miejsc)
VALUES ('Wieliczka','Polska',TO_DATE('2021-05-15','YYYY-MM-DD'),'Zadziwiająca kopalnia ...',4);

INSERT INTO wycieczki (nazwa, kraj, data, opis, liczba_miejsc)
VALUES ('Warszawa','Polska',TO_DATE('2020-04-07','YYYY-MM-DD'),'Stolica Polski ...',2);

--rezerwacje
INSERT INTO rezerwacje(id_wycieczki, id_osoby, status)
VALUES (1,1,'Z');

INSERT INTO rezerwacje(id_wycieczki, id_osoby, status)
VALUES (1,2,'P');

INSERT INTO rezerwacje(id_wycieczki, id_osoby, status)
VALUES (1,3,'N');

INSERT INTO rezerwacje(id_wycieczki, id_osoby, status)
VALUES (2,4,'A');

INSERT INTO rezerwacje(id_wycieczki, id_osoby, status)
VALUES (2,5,'Z');

INSERT INTO rezerwacje(id_wycieczki, id_osoby, status)
VALUES (3,6,'P');

INSERT INTO rezerwacje(id_wycieczki, id_osoby, status)
VALUES (3,7,'A');

INSERT INTO rezerwacje(id_wycieczki, id_osoby, status)
VALUES (3,8,'P');

INSERT INTO rezerwacje(id_wycieczki, id_osoby, status)
VALUES (4,9,'Z');

INSERT INTO rezerwacje(id_wycieczki, id_osoby, status)
VALUES (4,10,'P');