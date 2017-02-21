# utilities

lib:
with lib;

let
  documentedFunction' = data: arg:
    if arg == { _type = "genDoc"; }
    then (data // { _type = "docFunction"; })
    else data.function arg;

in rec {

  _documentation = _: ''
    This namespace contains generic functions.
  '';

/*
===============================================================

 is

===============================================================
*/

  is = documentedFunction {
    description = "Check if an attribute set has a certain type.";

    arguments = [
      {
        name = "type";
        description = "Type to check.";
        type = "String";
      }
      {
        name = "attrs";
        description = "Attribute set to check.";
        type = "Attrs";
      }
    ];

    return = "`Bool`";

    examples = [ (mkExample {
      literalCode = ''
        is "foo" { _type = "foo"; }
      '';
      code =
        is "foo" { _type = "foo"; }
      ;
      expected = true;
    })];

    function = type: x: isAttrs x && x ? _type && x._type == type;
  };



/*
===============================================================

 isExample

===============================================================
*/

  isExample = documentedFunction {
    description = "Check if a set is an example.";

    arguments = [
      {
        name = "attrs";
        description = "Attribute set to check.";
        type = "Attrs";
      }
    ];

    examples = [ (mkExample {
      literalCode = ''
        isExample (mkExample {
          literalCode = "2 + 2";
          code = 2 + 2;
        })
      '';
      code =
        isExample (mkExample {
          literalCode = "2 + 2";
          code = 2 + 2;
        })
      ;
      expected = true;
    })];

    function = is "example";
  };



/*
===============================================================

 isDocExample

===============================================================
*/

  isDocFunction = documentedFunction {
    description = "Check if a set is a documented fuction.";

    arguments = [
      {
        name = "attrs";
        description = "Attribute set to check.";
        type = "Attrs";
      }
    ];

    return = "`Bool`";

    function = is "docFunction";
  };


/*
===============================================================

 mkExample

===============================================================
*/

  mkExample = documentedFunction {
    description = "Create an example set.";

    return = "An example attribute set.";

    function = {
      literalCode ? null
    , code ? null
    , displayCode ? id
    , expected ? null
    }@args:
    args // { _type = "example"; inherit displayCode; };
  };


/*
===============================================================

 documentedFunction

===============================================================
*/

  documentedFunction = documentedFunction' {
    description = "Create a documented function. A documented function is used to automatically generate documentation and tests.";

    arguments = {
      function = {
        description = "The function to document.";
      };
      description = {
        description = "Function description, asciidoc markup can be used.";
        type = "String";
      };
      arguments = {
        description = "Function arguments documentation. Attrs if the arguments are an attribute set, List for standard arguments.";
        type = "Null | Attrs | List";
        default = null;
      };
      examples = {
        description = "Examples of usages defined with `mkExample`.";
        type = "Null | [ Example ]";
      };
      return = {
        description = "Description of function return value, asciidoc markup can be used.";
        type = "String";
      };
      notes = {
        description = "Notes regarding special usages, asciidoc markup can be used.";
        type = "Mull | String";
        default = "Null";
      };
    };

    return = "The template function, or the documented template set if `env` has a `genDoc` attribute set to `true`.";

    function = {
      description
    , function
    , arguments ? null
    , return ? null
    , examples ? []
    , notes ? null
    }@data: arg:
      if arg == { _type = "genDoc"; }
      then (data // { _type = "docFunction"; })
      else data.function arg;
  };



/*
===============================================================

 chunksOf

===============================================================
*/

  chunksOf = documentedFunction {
    description = "Split a list in lists multiple lists of `size` items.";

    arguments = [
      {
        name = "size";
        description = "Maximum size of the splitted lists.";
        type = "Integer";
      }
      {
        name = "list";
        description = "List to split.";
        type = "List";
      }
    ];

    return = ''
      A list of lists of `size` size.
    '';

    examples = [ (mkExample {
      literalCode = "chunksOf 2 [ 1 2 3 4 5 ]";
      code        = chunksOf 2 [ 1 2 3 4 5 ];
      expected    = [ [ 1 2 ] [ 3 4 ] [ 5 ] ];
    })];

    function = k:
      let f = ys: xs:
            if xs == []
            then ys
            else f (ys ++ [(take k xs)]) (drop k xs);
      in f [];
  };


/*
===============================================================

 merge

===============================================================
*/

  merge = documentedFunction {
    description = "Merge recursively a list of sets.";

    examples = [ (mkExample {
      literalCode = ''
        conf = lib.utils.merge [
          (lib.themes.loadConf { inherit themes; })
          (import ./conf.nix)
          extraConf
        ];
      '';
    }) (mkExample {
      literalCode = ''
        merge [ { a = 1; b = 2; } { b = "x"; c = "y"; } ]
      '';
      code =
        merge [ { a = 1; b = 2; } { b = "x"; c = "y"; } ]
      ;
      expected = { a = 1; b = "x"; c = "y"; };
    })];

    function = foldl' (set: acc:
        recursiveUpdate set acc
      ) {};
  };


/*
===============================================================

 sortBy

===============================================================
*/

  sortBy = documentedFunction {
    description = "Sort a list of attribute sets by attribute.";

    examples = [ (mkExample {
      literalCode = ''
        sortBy "priority" "asc" [ { priority = 5; } { priority = 2; } ]
      '';
      code =
        sortBy "priority" "asc" [ { priority = 5; } { priority = 2; } ]
      ;
      expected = [ { priority = 2; } { priority = 5; } ];
    })];

    function = attribute: order:
      sort (a: b:
             if order == "asc" then a."${attribute}" < b."${attribute}"
        else if order == "dsc" then a."${attribute}" > b."${attribute}"
        else    abort "Sort order must be 'asc' or 'dsc'");
  };


/*
===============================================================

 dirContains

===============================================================
*/

  dirContains = documentedFunction {
    description = "Check if a path exists in a directory.";

    function = dir: path:
      let
        pathArray = filter (x: x != "") (splitString "/" path);
        loop = base: path:
          let contents = readDir base;
          in if hasAttrByPath [ (head path) ] contents
             then if length path > 1
                  then loop (base + "/${head path}") (tail path)
                  else true
             else false;
      in loop dir pathArray;
  };


/*
===============================================================

 setToList

===============================================================
*/

  setToList = documentedFunction {
    description = "Convert a deep set to a list of sets where the key is the path.";

    examples = [ (mkExample {
      literalCode = ''
        setToList { a.b.c = true; d = "foo"; x.y.z = [ 1 2 3 ]; }
      '';
      code =
        setToList { a.b.c = true; d = "foo"; x.y.z = [ 1 2 3 ]; }
      ;
      expected = [ { "a.b.c" = true; } { d = "foo"; } { "x.y.z" = [ 1 2 3 ]; } ];
    }) ];

    function = s:
      let
      f = path: set:
        map (key:
          let
            value = set.${key};
            newPath = path ++ [ key ];
            pathString = concatStringsSep "." newPath;
          in
          if isAttrs value
             then f newPath value
             else { "${pathString}" = value; }
        ) (attrNames set);
      in flatten (f [] s);
  };



/*
===============================================================

 importApply

===============================================================
*/

  importApply = documentedFunction {
    description = "Import a nix file `file` and apply the arguments `arg` if it is a function.";

    arguments = [
      {
        name = "file";
        description = "Nix file to load.";
        type = "Path";
      }
      {
        name = "arg";
        description = "Argument to call `file` contents with if it is a function.";
      }
    ];

    function = file: arg:
      let f = import file;
      in if isFunction f then f arg else f;
  };



/*
===============================================================

 prettyNix

===============================================================
*/

  prettyNix = documentedFunction {
    description = "Pretty print nix values.";

    examples = [ (mkExample {
      literalCode = ''
        prettyNix [ { a.b.c = true; } { x.y.z = [ 1 2 3 ]; } ]
      '';
      code =
        prettyNix [ { a.b.c = true; } { x.y.z = [ 1 2 3 ]; } ]
      ;
      expected = ''
      [ {
        a = {
          b = {
            c = true;
          };
        };
      } {
        x = {
          y = {
            z = [ 1 2 3 ];
          };
        };
      } ]'';
    }) ];

    function = expr:
      let indent = n: concatStrings (genList (x: " ") (n*2));
          isLit = x: isAttrs x && x ? _type && x._type == "literalExample";
          loop   = n: x:
             if isString x then ''"${replaceStrings [''"''] [''\"''] x}"''
        else if isInt    x then toString x
        else if isNull   x then "null"
        else if isList   x then ''[ ${concatStringsSep " " (map (loop n) x)} ]''
        else if isBool   x then toJSON x
        else if x == {}    then ''{ }''
        else if isLit    x then x.text
        else if isAttrs  x then ''
        {
        ${indent (n+1)}${concatStringsSep "\n${indent (n+1)}" (mapAttrsToList (k: v: "${k} = ${loop (n+1) v};") x)}
        ${indent n}}''
        else if isFunction x then ''<LAMBDA>''
        else if (typeOf x == "path") then ''`${toString x}`''
        else "";
      in loop 0 expr;
  };
}
