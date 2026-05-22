package searchparam_test

import (
	"sync"
	"testing"

	"github.com/wso2/open-healthcare-fhir-server-go/internal/searchparam"
)

func def(rt, name, typ string) searchparam.Definition {
	return searchparam.Definition{
		ResourceType: rt,
		ParamName:    name,
		ParamType:    typ,
		FHIRPath:     rt + "." + name,
	}
}

func TestRegistry_Lookup_Found(t *testing.T) {
	r := searchparam.NewRegistry()
	r.Upsert(def("Patient", "name", "string"))

	d, ok := r.Lookup("Patient", "name")
	if !ok {
		t.Fatal("expected lookup to find definition")
	}
	if d.ParamType != "string" {
		t.Fatalf("got type %q, want %q", d.ParamType, "string")
	}
}

func TestRegistry_Lookup_NotFound(t *testing.T) {
	r := searchparam.NewRegistry()
	_, ok := r.Lookup("Patient", "nonexistent")
	if ok {
		t.Fatal("expected lookup to fail for unknown param")
	}
}

func TestRegistry_Upsert_Overwrites(t *testing.T) {
	r := searchparam.NewRegistry()
	r.Upsert(def("Patient", "name", "string"))
	r.Upsert(searchparam.Definition{
		ResourceType: "Patient",
		ParamName:    "name",
		ParamType:    "token", // changed
		FHIRPath:     "Patient.name",
		IsCustom:     true,
	})

	d, ok := r.Lookup("Patient", "name")
	if !ok {
		t.Fatal("expected lookup to find updated definition")
	}
	if d.ParamType != "token" {
		t.Fatalf("got %q, want %q", d.ParamType, "token")
	}
	if !d.IsCustom {
		t.Fatal("expected IsCustom=true after upsert")
	}
}

func TestRegistry_ForResource_AllDefs(t *testing.T) {
	r := searchparam.NewRegistry()
	r.Upsert(def("Patient", "name", "string"))
	r.Upsert(def("Patient", "birthdate", "date"))
	r.Upsert(def("Observation", "code", "token"))

	patDefs := r.ForResource("Patient")
	if len(patDefs) != 2 {
		t.Fatalf("want 2 Patient defs, got %d", len(patDefs))
	}
	obsDefs := r.ForResource("Observation")
	if len(obsDefs) != 1 {
		t.Fatalf("want 1 Observation def, got %d", len(obsDefs))
	}
}

func TestRegistry_ForResource_Empty(t *testing.T) {
	r := searchparam.NewRegistry()
	defs := r.ForResource("Encounter")
	if len(defs) != 0 {
		t.Fatalf("expected empty slice, got %d", len(defs))
	}
}

func TestRegistry_Remove_ExistingParam(t *testing.T) {
	r := searchparam.NewRegistry()
	r.Upsert(def("Patient", "name", "string"))
	r.Upsert(def("Patient", "birthdate", "date"))

	r.Remove("Patient", "name")

	_, ok := r.Lookup("Patient", "name")
	if ok {
		t.Fatal("expected name to be removed")
	}
	// birthdate should still be there
	defs := r.ForResource("Patient")
	if len(defs) != 1 || defs[0].ParamName != "birthdate" {
		t.Fatalf("expected birthdate to remain, got %v", defs)
	}
}

func TestRegistry_Remove_NonExistent(t *testing.T) {
	r := searchparam.NewRegistry()
	// Should not panic
	r.Remove("Patient", "nonexistent")
}

func TestRegistry_MultipleResourceTypes(t *testing.T) {
	r := searchparam.NewRegistry()
	resources := []string{"Patient", "Observation", "Condition", "Encounter", "MedicationRequest"}
	for _, rt := range resources {
		r.Upsert(def(rt, "status", "token"))
		r.Upsert(def(rt, "_id", "token"))
	}

	for _, rt := range resources {
		defs := r.ForResource(rt)
		if len(defs) != 2 {
			t.Errorf("%s: want 2 defs, got %d", rt, len(defs))
		}
	}
}

func TestRegistry_ConcurrentAccess(t *testing.T) {
	r := searchparam.NewRegistry()
	r.Upsert(def("Patient", "name", "string"))

	var wg sync.WaitGroup
	for i := 0; i < 50; i++ {
		wg.Add(2)
		go func() {
			defer wg.Done()
			r.Lookup("Patient", "name")
		}()
		go func() {
			defer wg.Done()
			r.Upsert(def("Patient", "name", "string"))
		}()
	}
	wg.Wait()
}

func TestRegistry_IGSource(t *testing.T) {
	r := searchparam.NewRegistry()
	r.Upsert(searchparam.Definition{
		ResourceType: "Patient",
		ParamName:    "us-core-race",
		ParamType:    "token",
		FHIRPath:     "Patient.extension('http://hl7.org/fhir/us/core/StructureDefinition/us-core-race')",
		IsCustom:     false,
		IGSource:     "hl7.fhir.us.core@6.1.0",
	})

	d, ok := r.Lookup("Patient", "us-core-race")
	if !ok {
		t.Fatal("expected to find IG-sourced param")
	}
	if d.IGSource != "hl7.fhir.us.core@6.1.0" {
		t.Fatalf("got IGSource %q, want %q", d.IGSource, "hl7.fhir.us.core@6.1.0")
	}
}
