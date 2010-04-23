/** A save method with copy-on-write semantics.
 * All records matching the Query object will reference the new data;
 * everything else references the old data.
 *
 * @see baseModel::save()
 * @param Query $q query for selecting related records
 * @return int number of records saved
 */
function save(Query $q=null) {
	$q = $q ? clone $q : new Query;
	$count = 0;

	// we only need to copy if there are multiple references to this object
	$u = $this->getUsers();
	$refusers = $this->getUsers($q);

	// test for all the cases where we don't want to copy
	// this is every column except metadata for this table
	if (!$this->isNew() &&
		count($u) > count($refusers) &&
		(
			$this->isColumnModified('firstname') ||
			$this->isColumnModified('lastname')
		)
	) {
		// @see baseModel::copy()
		$that = $this->copy();

		// start a transaction, since we're modding (potentially) tons of records
		// the entire COW is an atomic operation
		$con = self::getConnection();
		$con->beginTransaction();
		try {
			// save the other record so it gets a new ID
			$count = $that->save();
			assert($this->getUserdataid()!=$that->getUserdataid());

			// "switch" to the new record, since we can't do
			// $this = $that;
			$this->fromArray($that->toArray());
			$this->resetModified();
			$this->setNew(false);

			// update all the records that need to point to new data
			foreach ($refusers as $user) {
				$user->setUserdataid($this->getUserdataid());
				$count += $user->save();
			}

			$con->commit();
		} catch (Exception $e) {
			$con->rollback();
			throw $e;
		}
	}

	return $count + parent::save();
}
