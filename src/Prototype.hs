module Prototype where

import Data
import DataUtil
import Driving
import Folding
import Generator
import Data.List

transform :: Task -> Task
transform (e, p) =
    residuate $ foldTree $ buildFTree (driveMachine p) e

buildFTree :: Machine Conf -> Conf -> Tree Conf
buildFTree m = bft m nameSupply

bft :: Machine Conf -> NameSupply -> Conf -> Tree Conf
bft d (n:ns) e | whistle e = bft d ns $ generalize n e
bft d ns     t =
  case d ns t of
    Decompose comp ds -> Node t $ EDecompose comp $ map (bft d ns) ds
    Transient tr e -> Node t $ ETransient tr $ bft d ns e
    Stop e -> Leaf e
    Variants cs -> Node t $ EVariants [(c, bft d (unused c ns) e) | (c, e) <- cs]

sizeBound = 40
whistle :: Expr -> Bool
whistle e@(FCall _ args) = not (all isVar args) && size e > sizeBound
whistle e@(GCall _ args) = not (all isVar args) && size e > sizeBound
whistle _ = False

generalize :: Name -> Expr -> Expr
generalize n (FCall f es) =
    Let (n, e) (FCall f es') where (e, es') = extractArg n es
generalize n (GCall g es) =
    Let (n, e) (GCall g es') where (e, es') = extractArg n es

extractArg :: Name -> [Expr] -> (Expr, [Expr])
extractArg n es = (maxE, vs ++ Var n : ws) where
    maxE = maximumBy ecompare es
    ecompare x y = compare (eType x * size x) (eType y * size y)
    (vs, w : ws) = break (maxE ==) es
    eType e = if isVar e then 0 else 1
