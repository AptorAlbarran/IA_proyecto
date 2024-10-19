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
% punto 2 

%[inserte el código aquí]

% punto 3

%[inserte el código aquí]

% punto 4

%[inserte el código aquí]
