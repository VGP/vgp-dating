"""Focused checks of the optimizer's score handling and selection rules."""
import importlib.util
import math
from pathlib import Path
import unittest

source = Path(__file__).resolve().parents[1] / 'treepl_benchmark.py'
spec = importlib.util.spec_from_file_location('optimizer', source)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


class Optimization(unittest.TestCase):
    def test_score_extraction_and_numeric_filter(self):
        prefix = 'conducting RANDOM SUBSAMPLE cross validation analysis\n'
        prefix += ''.join(f'cv sample {i}: a b\npost opt cv check: {100+i}\n' for i in range(10))
        for raw, expected in [('12345.678', True), ('1e43', False)]:
            saved = f'chisq: (0.01) {raw}\n'
            score, folds, masks = mod.parse_cv(prefix+saved, saved, .01)
            self.assertEqual(score, float(raw))
            self.assertEqual(folds, list(range(100,110)))
            self.assertEqual(mod.accepted(score, 1e12), expected)
        for value in (float('nan'), float('inf'), -1):
            self.assertFalse(mod.accepted(value, 1e12))
        with self.assertRaises(ValueError):
            mod.parse_cv(prefix+'chisq: (0.01) nan\n', 'chisq: (0.01) nan\n', .01)

    def test_sweep_parser_separates_training_folds(self):
        header = 'conducting RANDOM SUBSAMPLE cross validation analysis\n'
        header += ''.join(f'cv sample {i}: a b\n' for i in range(10))
        log,saved = header,''
        for sm,value in [(100.,500.),(1.,200.),(.01,100.)]:
            log += ''.join(f'post opt cv check: {value+i}\n' for i in range(10))
            score = f'chisq: ({sm}) {value}\n'
            log += score
            saved += score
        score,folds,masks = mod.parse_cv(log,saved,1.)
        self.assertEqual(score,200.)
        self.assertEqual(folds,list(range(200,210)))
        self.assertEqual(len(masks),10)

    @staticmethod
    def row(req, x, score, objective=100.):
        return dict(job=dict(smoothing=10**x,rep=req['rep'],cvseed=req['cvseed']),
                    status='complete',score=score,objective=objective,folds=[objective]*10)

    def test_retries_preserve_cv_samples_and_select_medians(self):
        calls,failures = [],7
        def evaluate(requests):
            nonlocal failures
            rows = []
            for req in requests:
                for x in req['xs']:
                    calls.append((x,req['rep'],req['cvseed'],req['seed']))
                    bad = x == -2 and req['rep'] == 1 and failures > 0
                    if bad:
                        failures -= 1
                    score = [1.,100.,101.,102.][req['rep']] if x == 0 else 10.
                    row = self.row(req,x,score)
                    row['status'] = 'discarded' if bad else 'complete'
                    rows.append(row)
            return rows
        search = mod.SmoothingSearch(evaluate,[1.,.01,.0001],10,replicates=4)
        scores = search.ensure([0,-2])
        self.assertEqual(min(scores,key=scores.get),-2)
        retries = [r for r in calls if r[:2]==(-2,1)]
        self.assertEqual(len(retries),8)
        self.assertEqual(len({r[2] for r in retries}),1)
        self.assertEqual(len({r[3] for r in retries}),8)
        self.assertEqual(len([r for r in calls if r[0]==0]),4)

    def test_both_minima_and_improving_boundaries_are_refined(self):
        seen = []
        def evaluate(requests):
            rows = []
            for req in requests:
                for x in req['xs']:
                    seen.append((x,req['rep'],req['cvseed']))
                    score = min(1+(x+1.2)**2,1.1+(x-5.3)**2) + .001*req['rep']
                    rows.append(self.row(req,x,score))
            return rows
        search = mod.SmoothingSearch(evaluate,[1,100,10000],123,tolerance=0)
        best = math.log10(search.run())
        self.assertLess(abs(best+1.2),.25)
        self.assertTrue(any(x>5 for x,_,_ in seen))
        self.assertTrue(any(x<-1 for x,_,_ in seen))
        self.assertTrue(any(abs(x-5.3)<.25 for x,_,_ in seen))
        self.assertEqual(len({seed for _,_,seed in seen}),8)
        for x in search.medians():
            self.assertEqual({r for y,r in search.samples if y==x},set(range(8)))

    def test_near_tied_boundaries_extend_until_upturn_or_numeric_plateau(self):
        self.assertEqual(mod.refinement_points({-10:10.,-8:10.01,-6:10.02}),[-11])
        self.assertEqual(mod.refinement_points({-4:10.02,-2:10.01,0:10.}),[1])
        self.assertEqual(mod.refinement_points({-11:10.001,-10:10.,-8:10.01}),[])
        self.assertEqual(mod.refinement_points({-10:10.,-8:10.+1e-10,-6:10.02}),[])
        self.assertEqual(mod.refinement_points({-10:10.,-8:10.,-6:10.02}),[])

    def test_coarse_grid_continues_from_high_to_low_smoothing(self):
        grid = [4,2,0,-2,-4,-6,-8,-10]
        groups = list(mod.descending_groups(grid))
        self.assertEqual([x for group in groups for x in group],grid)
        self.assertEqual([group[0] for group in groups],[4])
        for group in groups:
            if len(group)>2:
                self.assertEqual(len({x-y for x,y in zip(group,group[1:])}),1)

    def test_largest_smoothing_within_cv_tolerance_wins(self):
        scores = {-10:24208.612, -8:24437.127, -6:26327.878}
        self.assertEqual(mod.select_smoothing(scores,.01),-8)
        self.assertEqual(mod.select_smoothing(scores,0),-10)
        self.assertEqual(mod.select_smoothing({-10:100.,-8:100.},0),-8)

    def test_continuation_preserves_independent_replicates(self):
        optimizer = object.__new__(mod.Optimizer)
        optimizer.curves = {(-4,0):dict(state='own.state',objective=20.),
                            (-4,1):dict(state='other.state',objective=10.)}
        self.assertEqual(optimizer.curve_starts(1e-6,0),('own.state',None))

    def test_polishing_keeps_complementary_screened_methods(self):
        candidates = [mod.profile(opt=i,optad=j) for i,j in [(0,1),(0,2),(2,3),(1,2),(3,4)]]
        self.assertEqual(mod.polish_methods(candidates,4),((0,1,4),(0,2,4),(2,3,4)))

    def test_better_training_updates_scores_even_when_cv_increases(self):
        generation = 0
        def evaluate(requests):
            nonlocal generation
            score,objective = [(10.,100.),(20.,90.),(1.,110.)][generation]
            generation += 1
            return [self.row(req,x,score,objective) for req in requests for x in req['xs']]
        search = mod.SmoothingSearch(evaluate,[.01,1,100],12)
        self.assertEqual(search.ensure([0])[0],10.)
        self.assertEqual(search.ensure([0],refresh=True)[0],20.)
        self.assertEqual(search.ensure([0],refresh=True)[0],20.)

    def test_optimizer_ranking_uses_training_fit_and_medians(self):
        rows = []
        for opt, values, score in [(1,[1.,20.,30.],1.), (2,[10.,11.,12.],100.)]:
            for seed, value in enumerate(values):
                rows.append(dict(job=dict(profile=mod.profile(opt=opt),smoothing=1.,seed=seed),
                    status='complete',objective=value,folds=[value]*10,score=score,seconds=1.))
        self.assertEqual(mod.rank_profiles(rows)[0]['opt'], 2)
        # Training fit and prediction score serve different selection steps.
        self.assertEqual(mod.rank_profiles(rows,cv=True)[0]['opt'], 2)
        rows = [dict(job=dict(profile=mod.profile(opt=i),smoothing=1e-11),status='complete',
                     objective=value,seconds=seconds) for i,value,seconds in
                [(1,5236.9605,10.),(2,5236.961,1.)]]
        self.assertEqual(mod.rank_profiles(rows)[0]['opt'],1)

    def test_cv_ties_prefer_less_effort_before_runtime(self):
        rows = [dict(job=dict(profile=mod.profile(moredetailcvad=detail,cviter=iterations),
                             smoothing=1.,seed=1),status='complete',folds=[value]*10,seconds=seconds)
                for detail,iterations,value,seconds in
                [(0,3,100.+1e-12,10.),(1,3,100.,1.),(0,6,100.,2.),(1,6,100.,.5)]]
        ranked = mod.rank_profiles(rows,cv=True)
        self.assertEqual([(p['moredetailcvad'],p['cviter']) for p in ranked],
                         [(0,3),(0,6),(1,3),(1,6)])
        rows[-1]['folds'] = [99.]*10
        self.assertEqual(mod.rank_profiles(rows,cv=True)[0],rows[-1]['job']['profile'])

    def test_export_preserves_constraints_and_removes_custom_controls(self):
        original = ('startstate = /tmp/old\notherstate = /tmp/other\nstateout = state\n'
                    'polish = 0/1/3\ncvseed = 12\ncvlocal\nopt = 2\nsmooth = 9.9999999999999994e-12\n'
                    'mrca = ROOT a b\nmin = ROOT 10\nmax = ROOT 20\n')
        exported = mod.render_config(original,dict(treefile='input.tre',outfile='dated.tre',smooth='1e-11'),{})
        self.assertFalse(mod.CONTROL_KEYS.intersection(mod.settings(exported)))
        self.assertEqual(mod.settings(exported)['opt'],'2')
        self.assertEqual(float(mod.settings(exported)['smooth']),1e-11)
        self.assertIn('mrca = ROOT a b\nmin = ROOT 10\nmax = ROOT 20',exported)


if __name__ == '__main__':
    unittest.main()
