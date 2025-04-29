The files `executor_coord.x` and `db_coord.x` are adapted with cosmetic changes from https://github.com/groundhogchain/hogd/blob/january_demo/hogd/xdr/rpc.x

Questions:

- The coordinator must call `executorcoord_open_proposal_block` (respectively `executorcoord_open_validation_block`) before it can make calls to `executorcoord_propose_transaction` (respectively `executorcoord_validate_transaction`). At the end it must call `executorcoord_finish_block`.

- Does the coordinator need to call `dbcoord_open_snapshot` before it calls `executorcoord_propose_transaction` or `executorcoord_validate_transaction`?

- Assuming "yes" on the previous question, `dbcoord_commit_snapshot` should be called after `executorcoord_finish_block`?

- `dbcoord_close_snapshot` is called after `dbcoord_commit_snapshot`?

- Why are both `dbcoord_close_snapshot` and `dbcoord_commit_snapshot` needed?

