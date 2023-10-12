using ReTestItems, Aqua, RxEnvironments

Aqua.test_all(RxEnvironments; ambiguities = false)
runtests(
    RxEnvironments
)
