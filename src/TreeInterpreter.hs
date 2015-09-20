module TreeInterpreter where

import Data
import Data.List
import DataUtil
import Data.Maybe

intTree :: Tree Conf -> Env -> Value
intTree (Leaf e) env =
    e // env
-- TODO: here is the bottle-neck for let-expressions
-- what to do with let??
intTree (Node (Let (v, e1) e2) (EDecompose _ [t1, t2])) env =
    intTree t2 ((v, intTree t1 env) : env)
intTree (Node (Ctr cname _) (EDecompose comp ts)) env =
    comp $ map (\t -> intTree t env) ts
intTree (Node _ (ETransient _ t)) env =
    intTree t env
intTree (Node e (EVariants cs)) env =
    head $ catMaybes $ map (try env) cs
intTree (Node _ (EFold t ren)) env =
    intTree t $ map (\(k, v) -> (renKey k, v)) env where
        renKey k = maybe k fst (find ((k ==) . snd)  ren)

try :: Env -> (Contraction, Tree Conf) -> (Maybe Expr)
try env (Contraction v (Pat pn vs), t) =
    if cn == pn then (Just $ intTree t extEnv) else Nothing where
        c@(Ctr cn cargs) = (Var v) // env
        extEnv = zip vs cargs ++ env
