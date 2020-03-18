# Тестовое задание на Python / bash
Скрипт сборки приложения

### Требуется
Реализуй следующие функции в виде скрипта или приложения на Python / bash:
1. ~~Запуститься и выкачать данный репозиторий (git@github.com:kontur-exploitation/testcase-pybash.git) с файлом index.js (либо другим простейшим http-server'ом).~~
2. ~~Проверять наличие изменений во всех ветках репозитория в заданный интервал времени.~~
3. ~~При обнаружении изменений в ветке выкачать их и собрать приложение в Docker-образ (требуется написать подходящий Dockerfile).
4. ~~Придумать версионирование для образа и назначать версию в качестве тега образа.
5. ~~Docker-образ должен содержать метаданные:
    - ~~branch: ветка, из которой собран образ;
    - ~~сommit: хеш последнего коммита;
    - ~~maintainer: автор коммита.
6. ~~Остановить старый контейнер после сборки образа и запустить новый. В контейнере должен запуститься http-service (на 80 порту), доступный снаружи контейнера.

Задания со звездочкой:
  - Сохранять вывод приложения в лог-файл. Файл не должен удаляться вместе с контейнером.
  - Передавать вместе с запуском контейнера параметр, который будет указывать на путь к лог-файлу.
  - Образ должен быть небольшого размера.
  - Реализовать откат к предыдущей версии в случае, если запуск новой версии был неудачным.

### Результат
Основная часть задания выполнена полностью.

### Известные проблемы
  - Счётчик в каждой ветке должен быть свой, сейчас он общий
  - Нужен принцип распределения на какой порт хоста привязывать 80 порт контейнера, сейчас все контейнеры привязываются на localhost:80
