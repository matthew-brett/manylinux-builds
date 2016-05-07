""" Remove TCL and Tk libs from matplotlib wheel(s)
"""
from __future__ import print_function

from os import unlink
from os.path import join as pjoin, basename, exists, abspath
from argparse import ArgumentParser

from subprocess import check_call, check_output

TKAGG_SO = pjoin('matplotlib', 'backends', '_tkagg.so')
LIB_DIR = pjoin('matplotlib', '.libs')

from auditwheel.wheeltools import InWheelCtx


def get_needed(lib_fname):
    res = check_output(['patchelf', '--print-needed'] + [lib_fname])
    return [name.strip() for name in res.decode('latin1').splitlines()]


def rm_needed(lib_name, lib_fname):
    check_call(['patchelf', '--remove-needed', lib_name, lib_fname])


def untcl_wheel(whl_fname, out_fname, verbose=False):
    whl_fname = abspath(whl_fname)
    out_fname = abspath(out_fname)
    with InWheelCtx(whl_fname) as ctx:
        if not exists(TKAGG_SO):
            if verbose:
                print('No {} in {}'.format(TKAGG_SO, whl_fname))
            return
        needed = get_needed(TKAGG_SO)
        for name in needed:
            if 'libtcl' in name or 'libtk' in name:
                rm_needed(name, TKAGG_SO)
                target_fname = pjoin(LIB_DIR, name)
                if exists(target_fname):
                    unlink(target_fname)
        # Write the wheel
        ctx.out_wheel = out_fname


def get_parser():
    parser = ArgumentParser()
    parser.add_argument('whl_fnames', nargs='+')
    parser.add_argument('--verbose', action='store_true')
    parser.add_argument('--out-path')
    return parser


def main():
    args = get_parser().parse_args()
    for whl_fname in args.whl_fnames:
        out_fname = (pjoin(args.out_path, basename(whl_fname)) if args.out_path
                     else whl_fname)
        if args.verbose:
            print('Untcling {} to {}'.format(whl_fname, out_fname))
        untcl_wheel(whl_fname, out_fname, verbose=args.verbose)


if __name__ == "__main__":
    main()
