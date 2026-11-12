"""Compatibility entry point: compile the redesigned Directorate art set."""
from build_daily_art import compile_art
from daily_art import spec

if __name__=='__main__': compile_art(spec('PALEO'))
