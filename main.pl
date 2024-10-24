% punto 1

%[inserte el código aquí]
% Predicado principal para encontrar la extensión de una clase, controlando clases visitadas.
class_extension(Clase, BaseConocimiento, Ext) :-
    class_extension(Clase, BaseConocimiento, [], Ext).

% Predicado que incluye una lista de clases visitadas para evitar ciclos.
class_extension(Clase, BaseConocimiento, Visitadas, Ext) :-
    \+ miembro(Clase, Visitadas), % Asegurarse de que la clase no ha sido visitada aún
    findall(Objeto, (miembro(class(Clase, Objeto), BaseConocimiento)), ObjetosDirectos),
    findall(Objeto, (
        miembro(herencia(Clase, ClaseHijo), BaseConocimiento),
        class_extension(ClaseHijo, BaseConocimiento, [Clase|Visitadas], SubExt),
        miembro(Objeto, SubExt)
    ), ObjetosHerencia),
    append(ObjetosDirectos, ObjetosHerencia, Ext).

% Predicado para verificar si un hecho es miembro de una lista
miembro(X, [X|_]).
miembro(X, [_|T]) :- miembro(X, T).

% Si la clase ya ha sido visitada (para ciclos), no buscar más.
class_extension(Clase, _, Visitadas, []) :-
    miembro(Clase, Visitadas).


% Predicado general para obtener la extensión de cualquier propiedad.
property_extension(Propiedad, BaseConocimiento, Ext) :-
    property_extension(Propiedad, BaseConocimiento, [], Ext).

% Predicado auxiliar que evita ciclos y acumula las propiedades.
property_extension(Propiedad, BaseConocimiento, Visitadas, Ext) :-
    % Buscar propiedades directamente asignadas a objetos:
    findall((Objeto, Valor), miembro(propiedad(Objeto, Propiedad, Valor), BaseConocimiento), Directos),
    
    % Buscar propiedades heredadas desde las clases padre:
    findall((Objeto, Valor), (
        miembro(herencia(ClasePadre, ClaseHijo), BaseConocimiento),
        \+ miembro(ClaseHijo, Visitadas),  % Asegurar que no hemos visitado esta clase antes
        property_extension_clase(ClaseHijo, Propiedad, BaseConocimiento, [ClaseHijo|Visitadas], SubExt),
        miembro((Objeto, Valor), SubExt)
    ), Heredados),
    
    % Unir resultados de propiedades directas y heredadas:
    append(Directos, Heredados, Ext).

% Predicado que maneja las propiedades a nivel de clase y herencia.
property_extension_clase(Clase, Propiedad, BaseConocimiento, Visitadas, Ext) :-
    % Buscar propiedades asociadas a la clase (por herencia):
    findall((Objeto, Valor), miembro(propiedad(Clase, Propiedad, Valor), BaseConocimiento), PropClase),
    
    % Buscar objetos de la clase que heredan las propiedades:
    findall((Objeto, Valor), (
        miembro(class(Clase, Objeto), BaseConocimiento),
        miembro((Objeto, Valor), PropClase)
    ), Ext),
    
    % Si la clase tiene herencia, seguir buscando en las clases hijas:
    property_extension(Propiedad, BaseConocimiento, Visitadas, ExtHijos),
    append(Ext, ExtHijos, Ext).

% Predicado para verificar si un hecho es miembro de una lista.
miembro(X, [X|_]).
miembro(X, [_|T]) :- miembro(X, T).

% Definición del predicado relation_extension/3
relation_extension(Relation, KnowledgeBase, Result) :-
    findall(Obj, (call(Relation, Obj), member(call(Relation, Obj), KnowledgeBase)), Result).


% predicados para puntos 2 y 3

% Leer base de conocimientos desde un archivo .txt
read_kb(File, KB) :-
    open(File, read, Stream),
    read_terms(Stream, KB),
    close(Stream).

% Leer todos los términos del archivo, ignorando end_of_file
read_terms(Stream, []) :-
    at_end_of_stream(Stream).

read_terms(Stream, KB) :-
    read(Stream, H),
    ( H == end_of_file ->
        KB = []
    ;
        read_terms(Stream, T),
        KB = [H|T]
    ).

% Guardar la base de conocimientos en un archivo .txt
write_kb(File, KB) :-
    open(File, write, Stream),
    write_terms(Stream, KB),
    close(Stream).

% Escribir todos los términos en el archivo
write_terms(_, []).

write_terms(Stream, [H|T]) :-
    write(Stream, H), write(Stream, '.\n'),
    write_terms(Stream, T).

% punto 2 

% Añadir una clase a la base de conocimientos y guardarla en un archivo .txt
add_class(ClassName, ClassMother, CurrentKBFile, NewKBFile) :-
    read_kb(CurrentKBFile, CurrentKB),
    % Revisa si la clase ya existe
    ( member(class(ClassName, _, _, _, _), CurrentKB) ->
        write('Class already exists. Not adding a duplicate.\n'),
        NewKB = CurrentKB
    ; 
        % Añade la nueva clase si no existe
        append(CurrentKB, [class(ClassName, ClassMother, [], [], [])], NewKB)
    ),
    write_kb(NewKBFile, NewKB).

% Añadir un objeto a la base de conocimientos y guardarlo en un archivo .txt
add_object(ObjectName, ClassName, CurrentKBFile, NewKBFile) :-
    read_kb(CurrentKBFile, CurrentKB),
    append(CurrentKB, [object(ObjectName, ClassName, [])], NewKB),
    write_kb(NewKBFile, NewKB).

% Añadir una propiedad a una clase existente y guardarla en un archivo .txt
add_class_property(ClassName, PropertyName, PropertyValue, CurrentKBFile, NewKBFile) :-
    read_kb(CurrentKBFile, CurrentKB),
    select(class(ClassName, ClassMother, Properties, Methods, Metadata), CurrentKB, RestKB),
    NewProperties = [property(PropertyName, PropertyValue) | Properties],
    append(RestKB, [class(ClassName, ClassMother, NewProperties, Methods, Metadata)], NewKB),
    write_kb(NewKBFile, NewKB).

% Añadir una propiedad a un objeto existente y guardarla en un archivo .txt
add_object_property(ObjectName, PropertyName, PropertyValue, CurrentKBFile, NewKBFile) :-
    read_kb(CurrentKBFile, CurrentKB),
    select(object(ObjectName, ClassName, Properties), CurrentKB, RestKB),
    NewProperties = [property(PropertyName, PropertyValue) | Properties],
    append(RestKB, [object(ObjectName, ClassName, NewProperties)], NewKB),
    write_kb(NewKBFile, NewKB).

% Añadir una relación a una clase existente y guardarla en un archivo .txt
add_class_relation(ClassName, RelationName, RelatedClasses, CurrentKBFile, NewKBFile) :-
    read_kb(CurrentKBFile, CurrentKB),
    select(class(ClassName, ClassMother, Properties, Methods, Metadata), CurrentKB, RestKB),
    NewRelations = [relation(RelationName, RelatedClasses) | Metadata],
    append(RestKB, [class(ClassName, ClassMother, Properties, Methods, NewRelations)], NewKB),
    write_kb(NewKBFile, NewKB).

% Añadir una relación a un objeto existente y guardarla en un archivo .txt
add_object_relation(ObjectName, RelationName, RelatedObjects, CurrentKBFile, NewKBFile) :-
    read_kb(CurrentKBFile, CurrentKB),
    select(object(ObjectName, ClassName, Properties), CurrentKB, RestKB),
    NewRelations = [relation(RelationName, RelatedObjects) | Properties],
    append(RestKB, [object(ObjectName, ClassName, NewRelations)], NewKB),
    write_kb(NewKBFile, NewKB).

% punto 3

% Eliminar una clase de la base de conocimientos y guardar el resultado en un nuevo archivo
rm_class(ClassName, CurrentKBFile, NewKBFile) :-
    read_kb(CurrentKBFile, CurrentKB),
    select(class(ClassName, _, _, _, _), CurrentKB, NewKB),
    write_kb(NewKBFile, NewKB).

% Eliminar un objeto de la base de conocimientos y guardar el resultado en un nuevo archivo
rm_object(ObjectName, CurrentKBFile, NewKBFile) :-
    read_kb(CurrentKBFile, CurrentKB),
    select(object(ObjectName, _, _), CurrentKB, NewKB),
    write_kb(NewKBFile, NewKB).

% Eliminar una propiedad de una clase y guardar el resultado en un nuevo archivo
rm_class_property(ClassName, PropertyName, CurrentKBFile, NewKBFile) :-
    read_kb(CurrentKBFile, CurrentKB),
    % Encontrar la clase y eliminar la propiedad especificada
    select(class(ClassName, ClassMother, Properties, Methods, Metadata), CurrentKB, RestKB),
    select(property(PropertyName, _), Properties, NewProperties),
    append(RestKB, [class(ClassName, ClassMother, NewProperties, Methods, Metadata)], NewKB),
    write_kb(NewKBFile, NewKB).

% Eliminar una propiedad de un objeto y guardar el resultado en un nuevo archivo
rm_object_property(ObjectName, PropertyName, CurrentKBFile, NewKBFile) :-
    read_kb(CurrentKBFile, CurrentKB),
    % Encontrar el objeto y eliminar la propiedad especificada
    select(object(ObjectName, ClassName, Properties), CurrentKB, RestKB),
    select(property(PropertyName, _), Properties, NewProperties),
    append(RestKB, [object(ObjectName, ClassName, NewProperties)], NewKB),
    write_kb(NewKBFile, NewKB).

% Eliminar una relación de una clase y guardar el resultado en un nuevo archivo
rm_class_relation(ClassName, RelationName, CurrentKBFile, NewKBFile) :-
    read_kb(CurrentKBFile, CurrentKB),
    % Encontrar la clase y eliminar la relación especificada
    select(class(ClassName, ClassMother, Properties, Methods, Metadata), CurrentKB, RestKB),
    select(relation(RelationName, _), Metadata, NewMetadata),
    append(RestKB, [class(ClassName, ClassMother, Properties, Methods, NewMetadata)], NewKB),
    write_kb(NewKBFile, NewKB).

% Eliminar una relación de un objeto y guardar el resultado en un nuevo archivo
rm_object_relation(ObjectName, RelationName, CurrentKBFile, NewKBFile) :-
    read_kb(CurrentKBFile, CurrentKB),
    % Encontrar el objeto y eliminar la relación especificada
    select(object(ObjectName, ClassName, Properties), CurrentKB, RestKB),
    select(relation(RelationName, _), Properties, NewProperties),
    append(RestKB, [object(ObjectName, ClassName, NewProperties)], NewKB),
    write_kb(NewKBFile, NewKB).
    
% punto 4

%[inserte el código aquí]
