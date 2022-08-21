#!/usr/bin/perl
use strict;
use warnings;
use Mojo::Pg;

my $pg = Mojo::Pg->new('postgresql://user1:12345@127.0.0.1:5432/test');

# Начальное значение id для таблицы message
my $message_id = 1;

# Читаем все строки логов
while (defined($_ = <>)) {
    # Вырезаем последний \n
    chomp;

    # Делим лог на поля
    my ($date, $time, $int_id, $flag, $address, $other) = split / /, $_, 6;

    # Подготовим поля для БД
    my $created = join " ", ($date, $time);
    # Когда флаг не задан, address и other могут быть undefined,
    # чтобы убрать warning, используем grep с defined
    my $str = join " ", grep defined, ($int_id, $flag, $address, $other);

    if ($flag eq "<=") {
        # Если флаг <=, записываем сообщение в message
        $pg->db->insert('message', {created => $created, id => $message_id++, int_id => $int_id, str => $str});
    } else {
        # В остальных случаях записываем сообщение в log
        $pg->db->insert('log', {created => $created, int_id => $int_id, str => $str, address => $address});
    }
}
