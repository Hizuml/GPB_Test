#!/usr/bin/perl
use Mojolicious::Lite -signatures;
use Mojo::Pg;

my $pg = Mojo::Pg->new('postgresql://user1:12345@127.0.0.1:5432/test');

# Этот файл получен путем запуска mojo generate lite-app
get '/' => sub ($c) {
    $c->render(template => 'index');
};

post '/query' => sub ($c) {
    # Получаем адрес из параметров запроса
    my $address = $c->param("address");

    # Отправляем запрос в БД
    my $result = $pg->db->query(q<
        select * from (
            select created, int_id, str from message where int_id in (
                select distinct int_id from log where address = ?
            )
            union all
            select created, int_id, str from log where address = ?
        ) as alias order by int_id, created limit 101
        >, $address, $address);
    
    # Получаем результаты запроса и проверяем их количество
    my $arrayref = $result->arrays->to_array;
    my $toomuch = "";
    if ($result->rows > 100) {
        pop @{ $arrayref };
        # Покажем сообщение, что результатов больше лимита
        $toomuch = "... and others";
    }
    
    # Приготовим результаты к отправке, так как они в формате ссылок на массивы
    my @results;
    # Проходим по каждому результату и помещаем его в $entry
    for my $entry (@{ $arrayref }) {
        # Разделяем каждую строку, нам нужны только нулевой и второй элементы (created, str)
        my @row = @{ $entry };
        push @results, "$row[0] $row[2]";
    }

    $c->render(text => join "<br>", (@results, $toomuch));
};

app->start;
__DATA__

@@ index.html.ep
% layout 'default';
% title 'Welcome';
<form method="POST" action="query">
<input type="text" name="address">
<input type="submit">
</form>

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head><title><%= title %></title></head>
  <body><%= content %></body>
</html>
