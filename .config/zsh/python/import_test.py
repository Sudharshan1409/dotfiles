#!/usr/bin/env python3
import time

start_time = time.time()

import argparse
import os
import platform
import sys

from InquirerPy import inquirer
from InquirerPy.base.control import Choice
from InquirerPy.separator import Separator
from lib.common import (
    CONSOLE,
    STYLE,
    StyledArgumentParser,
    find_item_and_scope,
    fuzzy_select,
    get_group_selection,
    get_scope_selection,
    print_help_panel,
    prompt_with_interrupt_handler,
    read_registry,
    scope_item,
    write_registry,
)
from rich import box
from rich.table import Table

end_time = time.time()

print(f"Import time: {end_time - start_time:.4f}s", file=sys.stderr)
