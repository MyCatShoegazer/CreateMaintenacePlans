# Generate maintenance plans

## English

This T-SQL query generates meintenance plans for provided database in MS SQL Server, where maintenance plans are tasks for table statistics update, index defragmetation, intex rebuilding. All the maintenance tasks will be generated according to provided schedule.

## Russian

Данный T-SQL запрос создаёт планы регламентного обслуживания для указанной базы данных на СУБД MS SQL Server, где в задачи обслуживания входит обновление статистики по таблицам, дефрагментация индексов таблиц, а так же перестроение этих индексов. Задачи по регламентному обслуживанию создаются согласно задаваемому пользователем расписанию.

## English

### Requirements

For the correct work of scheduled maintenance task it is required that service _SQL Server Agent_ must be running. Else maintenance task will not be performed correctly.

## Russian

### Требования

Для корректной работы запланированных задач обслуживания на сервере должна быть запущена служба _Агент SQL Server_ для того экземпляра под управлением, которого будет выполняться запрос и задачи обслуживания. В противном случая не гарантируется исполнение запланированных событий, так как слубжа агента отслеживает их исполнение.

## English

### Usage

You should edit the next code fragment according to your schedule requirements:

```SQL
INSERT INTO _variables (variable, value) VALUES
	('dbName', 'AdventureWorks2014'),	-- database name
	('statsStartTime', '180000'), 		-- statistics update start time
	('statsFreqInterval', '1'),		-- statistics update frequency in days
	('defragStartTime', '200000'), 		-- index defragmentation start time
	('defragFreqInterval', '1'),		-- index defragmentation frequency in days
	('reindexStartTime', '220000'), 	-- index rebuilding start time
	('reindexFreqInterval', '1')		-- index rebuilding frequency in days
GO
```

### Использование

Необходимо отредактировать слудующий фрагмент кода запроса в соотвествии с требованиями к имени базы данных и расписанию регламентных работ:

```SQL
INSERT INTO _variables (variable, value) VALUES
	('dbName', 'AdventureWorks2014'),	-- имя базы данных
	('statsStartTime', '180000'), 		-- время начала обновления статистики
	('statsFreqInterval', '1'),		-- частота обновления статистики в днях
	('defragStartTime', '200000'), 		-- время начала дефрагментации индексов
	('defragFreqInterval', '1'),		-- частота дефрагментации в днях
	('reindexStartTime', '220000'), 	-- время начала реиндексации таблиц
	('reindexFreqInterval', '1')		-- частота реиндексации таблиц в днях
GO
```

## English

### Parameter description

All the query parameters accepts values of types NCHAR / NVARCHAR / VARCHAR.

## Russian

### Описание параметров

Все описываемые параметры принимают значения типа NCHAR / NVARCHAR / VARCHAR.

## English

### dbName parameter

This parameter accepts database name for which maintenance plans should be created.

> All the maintenance tasks will be created with prefix of _dbName_ in their names.

## Russian

### Параметер dbName

Данный параметр принимает имя базы данных, для которой требуется создать планы обслуживания.

> Все задачи и параметры расписания будут созданы с префиксом имени выбранной базы данных в своём названии.

## English

### statsStartTime parameter

Accepts tasks start time in 24 hour format, where as example value `210000` is equal to `21:00:00`.

## Russian

### Параметер statsStartTime

Указывает время в 24-х часовом формате, когда необходимо запускать задачу обновления статистики таблиц, где значение `210000` эквивалентно времени `21:00:00`.

## English

### statsFreqInterval parameter

Accepts task start frequency in days, where example value of `1` will be equal to everyday and value of `15` will be equal to every 15 days.

#### statsFreqInterval

Указывает частоту обновления статистики в днях, где значение `1` будет означать запуск задачи каждый день в указанное время **statsStartTime**, а значение `15` означает запуск задачи каждые 15 дней в указанное время **statsStartTime**.
