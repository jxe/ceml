ceml:
	tt lib/ceml/tt/*.treetop

test:
	testrb test

doc:
	cd guide; maruku --html guide.md
	cd guide; wkpdf --source guide.html --output guide.pdf
